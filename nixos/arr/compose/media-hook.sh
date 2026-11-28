#!/usr/bin/env bash
# arr-media-hook
#
# Socket-activated HTTP hook (see arr-hook.socket). Opening
#   http://<arr>:9199/hook?token=...&note=...&scope=media|all
# captures a full snapshot, answers with an HTML page naming the capture
# directory, and then restarts the media services (scope=media, default) or
# every service (scope=all) in the background.
#
# Nothing is listening between requests: systemd owns the socket and starts
# this script per connection. stdout is the HTTP connection only.

set -uo pipefail

TOKEN_HASH=${ARR_HOOK_TOKEN_HASH:?}
WATCHDOG=${ARR_WATCHDOG:?}
DEFAULT_SCOPE=media

log() { printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*" >&2; }

html_escape() { printf '%s' "${1:-}" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'; }

# $1 = title, $2 = body html
page() {
  printf '%s' "<!doctype html><html lang=en><head><meta charset=utf-8><title>$(html_escape "$1")</title><style>body{font-family:system-ui,sans-serif;background:#101418;color:#e6edf3;margin:0;padding:3rem 1.5rem;line-height:1.6}main{max-width:46rem;margin:0 auto}h1{font-size:1.6rem;margin:0 0 1.5rem}p{margin:.6rem 0}code{background:#1c232b;padding:.15rem .4rem;border-radius:4px;font-size:.9em}.muted{color:#8b949e}</style></head><body><main><h1>$(html_escape "$1")</h1>$2</main></body></html>"
}

# $1 = status line, $2 = html body
respond() {
  printf 'HTTP/1.1 %s\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %s\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n%s' \
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
    respond "405 Method Not Allowed" "$(page "Method not allowed" "<p>This endpoint only answers <code>GET</code>.</p>")"
    exit 0
    ;;
esac

if [ -z "$token" ] || [ "$(printf '%s' "$token" | sha256sum | cut -d' ' -f1)" != "$TOKEN_HASH" ]; then
  log "rejected: bad or missing token (length ${#token})"
  respond "403 Forbidden" "$(page "Forbidden" "<p>Bad or missing <code>token</code>.</p>")"
  exit 0
fi

case "$scope" in
  media | all) ;;
  *) scope="$DEFAULT_SCOPE" ;;
esac

log "accepted: scope=$scope note=$note"
if ! dir=$("$WATCHDOG" --action capture --note "$note") || [ -z "$dir" ]; then
  log "capture failed"
  respond "500 Internal Server Error" "$(page "Capture failed" "<p>Nothing was restarted. See <code>journalctl -u 'arr-hook@*'</code>.</p>")"
  exit 0
fi
log "captured: $dir"

respond "200 OK" "$(page "arr: capture saved, restart in progress" "<p>Evidence was captured <strong>before</strong> the restart:</p>
<p><code>$(html_escape "$dir")/report.txt</code></p>
<p>Restarting: <strong>$(html_escape "$scope")</strong> service(s). This takes about 15&nbsp;s; the capture above is already on disk.</p>
<p class=muted>note: $(html_escape "$note") &middot; $(date '+%Y-%m-%d %H:%M:%S %Z')</p>
<hr>
<p class=muted>Timeline: <code>/var/lib/arr-watchdog/probe.log</code><br>
Logs: <code>journalctl -t arr-media-hook -t arr-media-watchdog</code><br>
Do <strong>not</strong> reload this page to check progress &mdash; every request starts another restart.</p>")"

# The client has its answer; stop talking to the socket and do the slow part.
exec 1>/dev/null
log "restarting ($scope)"
if "$WATCHDOG" --action restart --scope "$scope"; then
  log "restart finished, probes clean"
else
  log "restart finished, probes NOT clean - see the capture above"
fi
