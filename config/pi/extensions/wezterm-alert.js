import path from "node:path"

function signalWezTerm(session) {
  if (!process.stdout.isTTY || !process.env.WEZTERM_PANE) return

  const payload = { alert: "pi_done", pid: process.pid }
  if (session) {
    payload.session = session
  }

  const encoded = Buffer.from(JSON.stringify(payload), "utf8").toString("base64")
  process.stdout.write(`\x1b]1337;SetUserVar=WEZTERM_AGENT_ALERT=${encoded}\x1b\\`)
}

export default function (pi) {
  pi.on("agent_settled", (_event, ctx) => {
    const named = pi.getSessionName?.()?.trim()
    const cwd = path.basename(process.cwd())
    const id = ctx?.sessionManager?.getSessionId?.()
    const fallback = cwd || (id ? String(id).slice(0, 8) : "Pi")
    signalWezTerm(named || fallback)
  })
}
