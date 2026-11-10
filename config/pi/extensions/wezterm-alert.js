import fs from "node:fs"
import os from "node:os"
import path from "node:path"
import { randomUUID } from "node:crypto"

const stateDir = process.env.XDG_RUNTIME_DIR || path.join(os.homedir(), ".cache")
const pendingDir = path.join(stateDir, "wezterm-agent-pending")

function queueAlert(session) {
  const pane = process.env.WEZTERM_PANE
  if (!pane) return

  try {
    fs.mkdirSync(pendingDir, { recursive: true, mode: 0o700 })
    const payload = {
      alert: "pi_done",
      pane,
      pid: process.pid,
      session,
      updated: Date.now(),
    }
    const name = `${pane}-${Date.now()}-${randomUUID()}.json`
    const tmp = path.join(pendingDir, `.${name}.tmp`)
    const file = path.join(pendingDir, name)
    fs.writeFileSync(tmp, JSON.stringify(payload))
    fs.renameSync(tmp, file)
  } catch {
    // Alert delivery is best-effort; never break the agent over it.
  }
}

export default function (pi) {
  pi.on("agent_settled", (_event, ctx) => {
    const named = pi.getSessionName?.()?.trim()
    const cwd = path.basename(process.cwd())
    const id = ctx?.sessionManager?.getSessionId?.()
    const fallback = cwd || (id ? String(id).slice(0, 8) : "Pi")
    queueAlert(named || fallback)
  })
}
