#!/usr/bin/env bash
# Recover arr containers that lost /mnt/media.
#
# dockerd auto-starts containers with `restart: unless-stopped` as soon as it is
# up. If that happens before /mnt/media is mounted, the containers bind the
# empty directory underneath the mount and never see the media disk until they
# are recreated: Jellyfin still lists the library (metadata lives in its
# database) but cannot play anything.
#
# The probe compares the device of every container's media bind mount (read
# from /proc/<pid>/mountinfo, so it needs nothing from inside the image) with
# the device of $HOST_PATH on the host. On a mismatch it captures evidence,
# restarts the affected services and, as a last resort, force-recreates them.

set -uo pipefail

HOST_PATH=/mnt/media
STATE_DIR=/var/lib/arr-watchdog
CAPTURE_DIR=$STATE_DIR/captures
FAIL_THRESHOLD=2 # consecutive bad checks before acting (after the first check of a boot)
RATE_LIMIT=900   # seconds between restart attempts
COMPOSE=${ARR_COMPOSE:-arr-compose}

log() { printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*"; }
state_get() {
  local v
  v=$(cat "$STATE_DIR/$1" 2>/dev/null)
  printf '%s' "${v:-${2:-0}}"
}
state_set() { printf '%s\n' "$2" > "$STATE_DIR/$1"; }
oneline() { printf '%s' "${1:-}" | tr '\n' ' '; }

install -d -m 0755 "$STATE_DIR" "$CAPTURE_DIR"

if ! mountpoint -q "$HOST_PATH"; then
  log "$HOST_PATH is not mounted, nothing this watchdog can fix"
  state_set failures 0
  exit 0
fi

media_dev=$(findmnt -n -o MAJ:MIN --target "$HOST_PATH" 2>/dev/null | tr -d '[:space:]')
if [ -z "$media_dev" ]; then
  log "cannot determine the device of $HOST_PATH"
  exit 0
fi

# "service<TAB>container-path[ container-path...]" for every service that
# bind-mounts part of the media disk.
affected=$(
  "$COMPOSE" config --format json 2>/dev/null |
    jq -r --arg root "$HOST_PATH" '
      .services | to_entries[]
      | .key as $svc
      | [ .value.volumes[]? | select((.source // "") | startswith($root)) | .target ] as $targets
      | select(($targets | length) > 0)
      | "\($svc)\t\($targets | join(" "))"'
)
if [ -z "$affected" ]; then
  log "no service mounts $HOST_PATH"
  exit 0
fi

containers=$("$COMPOSE" ps --format json 2>/dev/null | jq -rs 'flatten[] | "\(.Service)\t\(.Name)"' || true)

# service  container  container-path  device (major:minor of the mount)
probe() {
  local svc targets name pid target mp dev
  while IFS=$'\t' read -r svc targets; do
    [ -n "${svc:-}" ] || continue
    name=$(printf '%s\n' "$containers" | awk -F'\t' -v s="$svc" '$1 == s { print $2; exit }')
    [ -n "$name" ] || continue
    pid=$(docker inspect --format '{{.State.Pid}}' "$name" 2>/dev/null)
    [ "${pid:-0}" -gt 0 ] 2>/dev/null || continue
    for target in $targets; do
      mp=${target%/}
      dev=$(awk -v p="$mp" '$5 == p { d = $3 } END { print d }' "/proc/$pid/mountinfo" 2>/dev/null)
      printf '%s\t%s\t%s\t%s\n' "$svc" "$name" "$target" "${dev:-unmounted}"
    done
  done <<EOF
$affected
EOF
}

bad_services() {
  probe | awk -F'\t' -v want="$media_dev" '$4 != want { print $1 }' | sort -u
}

probed=$(probe)
if [ -z "$probed" ]; then
  log "no running container mounts $HOST_PATH, nothing to check"
  exit 0
fi

bad=$(printf '%s\n' "$probed" | awk -F'\t' -v want="$media_dev" '$4 != want { print $1 }' | sort -u)
if [ -z "$bad" ]; then
  [ "$(state_get failures)" = 0 ] || state_set failures 0
  exit 0
fi

# Act on the first check after a boot: that is when the race happens. Later on,
# require two consecutive bad checks so a container being recreated is not
# mistaken for a stale mount.
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
log "media bind mismatch in: $(oneline "$bad") (check $failures/$threshold)"
[ "$failures" -ge "$threshold" ] || exit 0

now=$(date +%s)
last=$(state_get last-restart)
# The first check after a boot is always allowed to act, even if a restart from
# before the reboot is still inside the rate-limit window.
if [ "$first_check" -eq 0 ] && [ $(( now - last )) -lt "$RATE_LIMIT" ]; then
  log "rate limited: $(( now - last ))s since the last restart"
  exit 0
fi

capture=$CAPTURE_DIR/$(date +%Y%m%dT%H%M%S)
install -d -m 0755 "$capture"
{
  echo "== $HOST_PATH on the host"
  findmnt -T "$HOST_PATH"
  echo
  echo "== expected device: $media_dev"
  echo "== probe: service  container  container-path  device"
  probe
  echo
  echo "== compose ps"
  "$COMPOSE" ps || true
  echo
  echo "== disk"
  df -h "$HOST_PATH" 2>/dev/null || true
} > "$capture/report.txt"
find "$CAPTURE_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' 2>/dev/null |
  sort -rn | tail -n +11 | cut -d' ' -f2- | xargs -r rm -rf

state_set last-restart "$now"
log "restarting: $(oneline "$bad")"
# shellcheck disable=SC2086  # newline separated service list
"$COMPOSE" restart $bad || log "restart failed"
sleep 10

still=$(bad_services)
state_set failures 0
if [ -n "$still" ]; then
  log "still mismatched after restart: $(oneline "$still"), force recreating"
  # shellcheck disable=SC2086  # newline separated service list
  "$COMPOSE" up -d --force-recreate $still || log "force-recreate failed"
  exit 1
fi

log "recovered"
