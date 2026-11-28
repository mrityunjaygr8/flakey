#!/usr/bin/env bash
# arr-media-hook
#
# Socket-activated HTTP hook (see arr-hook.socket). Opening
#   http://<arr>:9199/hook?token=...&note=...&scope=media|all
# captures a full snapshot, answers immediately with the capture directory, and
# then restarts the media services (scope=media, default) or every service
# (scope=all) in the background.
#
# Nothing is listening between requests: systemd owns the socket and starts
# this script per connection. stdout is the HTTP connection only.

set -uo pipefail

TOKEN_HASH=${ARR_HOOK_TOKEN_HASH:?}
WATCHDOG=${ARR_WATCHDOG:?}
DEFAULT_SCOPE=media

log() { printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*" >&2; }
respond() {
  # $1 = status, $2 = body
  printf 'HTTP/1.1 %s\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' \
    "$1" "${#2}" "$2"
}

IFS= read -r request_line || true
method=${request_line%% *}
target=${request_line#* }
target=${target%% *}
path=${target%%\?*}
query=${target#*\?}
[ "$query" = "$target" ] && query=""

log "request: ${method:-?} ${path:-?}"

token=""
note="hook"
scope="$DEFAULT_SCOPE"
if [ -n "$query" ]; then
  IFS='&' read -ra params <<< "$query"
  for param in "${params[@]}"; do
    case "$param" in
      token=*) token=${param#token=} ;;
      note=*)
        note=${param#note=}
        note=${note//+/ }
        note=${note//%20/ }
        ;;
      scope=*) scope=${param#scope=} ;;
    esac
  done
fi

case "$method" in
  GET | POST) ;;
  *)
    log "rejected: method ${method:-none}"
    respond "405 Method Not Allowed" "use GET
"
    exit 0
    ;;
esac

if [ -z "$token" ] || [ "$(printf '%s' "$token" | sha256sum | cut -d' ' -f1)" != "$TOKEN_HASH" ]; then
  log "rejected: bad or missing token (length ${#token})"
  respond "403 Forbidden" "bad or missing token
"
  exit 0
fi

case "$scope" in
  media | all) ;;
  *) scope="$DEFAULT_SCOPE" ;;
esac

log "accepted: scope=$scope note=$note"
dir=$("$WATCHDOG" --action capture --note "$note")
log "captured: $dir"

respond "200 OK" "captured: $dir
report: $dir/report.txt
restarting: $scope
journal: journalctl -t arr-media-hook -t arr-media-watchdog
"

# The client has its answer; stop talking to the socket and do the slow part.
exec 1>/dev/null
log "restarting ($scope)"
if "$WATCHDOG" --action restart --scope "$scope"; then
  log "restart finished, probes clean"
else
  log "restart finished, probes NOT clean - see the capture above"
fi
