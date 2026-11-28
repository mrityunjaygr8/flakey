#!/usr/bin/env bash
# arr-media-watchdog
#
# Watches arr containers that use the media disk and recovers them when they
# cannot read it. Also the worker behind the manual HTTP hook
# (`--force`), which captures evidence on demand and restarts the services.
#
# Two independent probes, because they catch different failures:
#   mount - the device behind each container's media bind mount must be the
#           same device as $HOST_PATH on the host (catches containers created
#           before the mount existed, i.e. the boot race).
#   read  - a real 4 KiB read of a media file *through* the container must
#           succeed (catches a dead/stale superblock after a remount, a
#           read-only filesystem, permission changes, ...).
#
# Every run appends one line to $STATE_DIR/probe.log so the timeline of a slow
# degradation (e.g. "works for 12 hours, then fails") is visible afterwards.
#
# Usage: arr-media-watchdog [--force] [--scope media|all] [--note TEXT]
#   --force   skip the probes: capture evidence and restart immediately. Prints
#             the capture directory as the last line on stdout.

set -uo pipefail

HOST_PATH=/mnt/media
STATE_DIR=/var/lib/arr-watchdog
CAPTURE_DIR=$STATE_DIR/captures
PROBE_LOG=$STATE_DIR/probe.log
FAIL_THRESHOLD=2 # consecutive bad checks before acting (except the first of a boot)
RATE_LIMIT=900   # seconds between restart attempts
READ_BYTES=4096
COMPOSE=${ARR_COMPOSE:-arr-compose}

FORCE=0
SCOPE=media
NOTE=none
while [ "$#" -gt 0 ]; do
  case "$1" in
    --force) FORCE=1 ;;
    --scope)
      shift
      SCOPE=${1:-media}
      ;;
    --note)
      shift
      NOTE=${1:-none}
      ;;
  esac
  shift
done

log() { printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*" >&2; }
state_get() {
  local v
  v=$(cat "$STATE_DIR/$1" 2>/dev/null)
  printf '%s' "${v:-${2:-0}}"
}
state_set() { printf '%s\n' "$2" > "$STATE_DIR/$1"; }
oneline() { printf '%s' "${1:-}" | tr '\n' ' '; }
probe_log() {
  printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*" >> "$PROBE_LOG"
  tail -n 2000 "$PROBE_LOG" > "$PROBE_LOG.tmp" && mv "$PROBE_LOG.tmp" "$PROBE_LOG"
}

install -d -m 0755 "$STATE_DIR" "$CAPTURE_DIR"

# "service<TAB>host-source<TAB>container-target" for every media bind mount.
mounts=$(
  "$COMPOSE" config --format json 2>/dev/null |
    jq -r --arg root "$HOST_PATH" '
      .services | to_entries[]
      | .key as $svc
      | .value.volumes[]?
      | select((.source // "") | startswith($root))
      | "\($svc)\t\(.source)\t\(.target)"'
)
if [ -z "$mounts" ]; then
  log "no service mounts $HOST_PATH"
  exit 0
fi

containers=$("$COMPOSE" ps --format json 2>/dev/null | jq -rs 'flatten[] | "\(.Service)\t\(.Name)"' || true)

container_of() {
  printf '%s\n' "$containers" | awk -F'\t' -v s="$1" '$1 == s { print $2; exit }'
}
container_pid() {
  docker inspect --format '{{.State.Pid}}' "$1" 2>/dev/null
}

# service  container  container-path  device-or-error
probe_mount() {
  local svc source target name pid mp dev
  while IFS=$'\t' read -r svc target; do
    [ -n "${svc:-}" ] || continue
    name=$(container_of "$svc")
    [ -n "$name" ] || continue
    pid=$(container_pid "$name")
    [ "${pid:-0}" -gt 0 ] 2>/dev/null || continue
    mp=${target%/}
    dev=$(awk -v p="$mp" '$5 == p { d = $3 } END { print d }' "/proc/$pid/mountinfo" 2>/dev/null)
    printf '%s\t%s\t%s\t%s\n' "$svc" "$name" "$target" "${dev:-unmounted}"
  done < <(printf '%s\n' "$mounts" | cut -f1,3)
}

# service  container  container-path  bytes-read
probe_read() {
  local svc source target name file rel cpath bytes
  while IFS=$'\t' read -r svc source target; do
    [ -n "${svc:-}" ] || continue
    name=$(container_of "$svc")
    [ -n "$name" ] || continue
    [ "$(container_pid "$name")" -gt 0 ] 2>/dev/null || continue
    file=$(find "$source" -maxdepth 5 -type f \( -name '*.mkv' -o -name '*.mp4' -o -name '*.m4b' -o -name '*.mp3' \) -print -quit 2>/dev/null)
    [ -n "$file" ] || continue
    rel=${file#"$source"}
    cpath=${target%/}$rel
    bytes=$(docker exec "$name" head -c "$READ_BYTES" "$cpath" 2>/dev/null | wc -c)
    printf '%s\t%s\t%s\t%s\n' "$svc" "$name" "$cpath" "${bytes:-0}"
  done < <(printf '%s\n' "$mounts")
}

bad_services() {
  {
    probe_mount | awk -F'\t' -v want="$media_dev" '$4 != want { print "mount:" $1 }'
    probe_read | awk -F'\t' -v want="$READ_BYTES" '$4 + 0 < want { print "read:" $1 }'
  } | sort -u
}

capture() {
  local dir name pid
  dir=$CAPTURE_DIR/$(date +%Y%m%dT%H%M%S)
  install -d -m 0755 "$dir"
  {
    echo "== when"
    date
    echo "uptime: $(cut -d. -f1 /proc/uptime)s"
    echo "note: $NOTE"
    echo
    echo "== $HOST_PATH on the host"
    findmnt -T "$HOST_PATH"
    df -h "$HOST_PATH" 2>/dev/null
    echo "expected device: ${media_dev:-unknown}"
    echo
    echo "== mount probe (service container container-path device)"
    probe_mount
    echo
    echo "== read probe (service container container-path bytes-read)"
    probe_read
    echo
    echo "== containers"
    "$COMPOSE" ps || true
    echo
    echo "== docker stats"
    docker stats --no-stream || true
    echo
    echo "== jellyfin process"
    pid=$(container_pid jellyfin)
    if [ "${pid:-0}" -gt 0 ]; then
      echo "pid: $pid"
      echo "open fds: $(find "/proc/$pid/fd" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)"
      grep -E '^(Threads|VmRSS|FDSize)' "/proc/$pid/status" 2>/dev/null
    fi
    echo "ffmpeg processes: $(pgrep -fc ffmpeg || echo 0)"
    echo
    echo "== sockets"
    ss -s 2>/dev/null | head -5
    echo
    echo "== transcode cache"
    du -sh /home/arr/arr/config/jellyfin/cache/transcodes 2>/dev/null
    find /home/arr/arr/config/jellyfin/cache/transcodes -mindepth 1 -maxdepth 1 2>/dev/null | wc -l
    echo
    echo "== kernel (usb / exfat / io)"
    dmesg -T 2>/dev/null | grep -iE 'usb|exfat|sd [0-9]|i/o error|reset' | tail -40
    echo
    echo "== jellyfin log (last 80 lines)"
    tail -80 "$(find /home/arr/arr/config/jellyfin/log -maxdepth 1 -name 'log_*.log' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)" 2>/dev/null |
      grep -vE 'CustomAuthentication' | tail -80
  } > "$dir/report.txt" 2>&1
  find "$CAPTURE_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' 2>/dev/null |
    sort -rn | tail -n +11 | cut -d' ' -f2- | xargs -r rm -rf
  printf '%s' "$dir"
}

# --- manual trigger -----------------------------------------------------------
# Capture first (that is the whole point), restart second, then verify.
if [ "$FORCE" -eq 1 ]; then
  media_dev=$(findmnt -n -o MAJ:MIN --target "$HOST_PATH" 2>/dev/null | tr -d '[:space:]')
  probe_log "manual scope=$SCOPE note=$NOTE"
  dir=$(capture)
  log "manual trigger ($NOTE): evidence at $dir/report.txt"

  if [ "$SCOPE" = all ]; then
    log "restarting the whole stack"
    "$COMPOSE" restart || log "restart failed"
  else
    mapfile -t media_services < <(printf '%s\n' "$mounts" | cut -f1 | sort -u)
    log "restarting: ${media_services[*]}"
    "$COMPOSE" restart "${media_services[@]}" || log "restart failed"
  fi

  sleep 10
  state_set failures 0
  still=$(bad_services)
  if [ -n "$still" ]; then
    log "manual restart left the stack unhappy: $(oneline "$still")"
    printf '%s\n' "$dir"
    exit 1
  fi
  log "manual restart done, probes clean"
  printf '%s\n' "$dir"
  exit 0
fi
# -----------------------------------------------------------------------------

if ! mountpoint -q "$HOST_PATH"; then
  log "$HOST_PATH is not mounted; nothing this watchdog can fix"
  probe_log "host-unmounted"
  state_set failures 0
  exit 0
fi

media_dev=$(findmnt -n -o MAJ:MIN --target "$HOST_PATH" 2>/dev/null | tr -d '[:space:]')
if [ -z "$media_dev" ]; then
  log "cannot determine the device of $HOST_PATH"
  exit 0
fi

probed=$(probe_mount)
if [ -z "$probed" ]; then
  log "no running container mounts $HOST_PATH, nothing to check"
  exit 0
fi

bad=$(bad_services)
if [ -z "$bad" ]; then
  probe_log "ok"
  [ "$(state_get failures)" = 0 ] || state_set failures 0
  exit 0
fi

# Act on the first check after a boot: that is when the boot race happens. Later
# on require two consecutive bad checks, and never restart twice in a row
# within RATE_LIMIT.
boot_id=$(cat /proc/sys/kernel/random/boot_id)
marker=$STATE_DIR/boot-$boot_id
threshold=$FAIL_THRESHOLD
first_check=0
if [ ! -f "$marker" ]; then
  threshold=1
  first_check=1
  : > "$marker"
  find "$STATE_DIR" -maxdepth 1 -name 'boot-*' ! -name "boot-$boot_id" -delete 2>/dev/null
fi

failures=$(( $(state_get failures) + 1 ))
state_set failures "$failures"
log "bad: $(oneline "$bad") (check $failures/$threshold)"
probe_log "BAD $(oneline "$bad") (check $failures/$threshold)"
[ "$failures" -ge "$threshold" ] || exit 0

now=$(date +%s)
last=$(state_get last-restart)
# The first check after a boot is always allowed to act, even if a restart from
# before the reboot is still inside the rate-limit window.
if [ "$first_check" -eq 0 ] && [ $(( now - last )) -lt "$RATE_LIMIT" ]; then
  log "rate limited: $(( now - last ))s since the last restart"
  exit 0
fi

mapfile -t services < <(printf '%s\n' "$bad" | cut -d: -f2 | sort -u)
capture_dir=$(capture)
log "evidence: $capture_dir/report.txt"

state_set last-restart "$now"
log "restarting: ${services[*]}"
"$COMPOSE" restart "${services[@]}" || log "restart failed"
sleep 10

still=$(bad_services)
state_set failures 0
if [ -n "$still" ]; then
  log "still bad after restart: $(oneline "$still"), force recreating"
  mapfile -t still_services < <(printf '%s\n' "$still" | cut -d: -f2 | sort -u)
  "$COMPOSE" up -d --force-recreate "${still_services[@]}" || log "force-recreate failed"
  exit 1
fi

log "recovered"
