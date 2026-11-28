#!/usr/bin/env bash
# arr-media-hook
#
# Socket-activated HTTP hook (see arr-hook.socket). Opening
#   http://<arr>:9199/hook?token=...&note=...&scope=media|all
# captures a full snapshot of the stack, then restarts the media services
# (scope=media, default) or every service (scope=all) and re-runs the probes.
#
# Nothing is listening between requests: systemd owns the socket and starts
# this script per connection.

set -uo pipefail

TOKEN_HASH=${ARR_HOOK_TOKEN_HASH:?}
WATCHDOG=${ARR_WATCHDOG:?}
DEFAULT_SCOPE=media

respond() {
  # $1 = status, $2 = body
  printf 'HTTP/1.1 %s\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' \
    "$1" "${#2}" "$2"
}

IFS= read -r request_line || true
method=${request_line%% *}
target=${request_line#* }
target=${target%% *}
query=${target#*\?}
[ "$query" = "$target" ] && query=""

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
    respond "405 Method Not Allowed" "use GET
"
    exit 0
    ;;
esac

if [ -z "$token" ] || [ "$(printf '%s' "$token" | sha256sum | cut -d' ' -f1)" != "$TOKEN_HASH" ]; then
  respond "403 Forbidden" "bad or missing token
"
  exit 0
fi

case "$scope" in
  media | all) ;;
  *) scope="$DEFAULT_SCOPE" ;;
esac

dir=$("$WATCHDOG" --force --scope "$scope" --note "$note")

respond "200 OK" "captured: $dir
restarted: $scope
report: $dir/report.txt
journal: journalctl -u 'arr-hook@*' -u arr-media-watchdog
"
