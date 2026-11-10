import { Plugin } from "@opencode/plugin/tui"

type Alert = "opencode_done" | "opencode_permission"

type AlertPayload = {
  alert: Alert
  pid: number
  session?: string
}

function signalWezTerm(alert: Alert, session?: string): void {
  if (!process.stdout.isTTY || !process.env.WEZTERM_PANE) return

  const payload: AlertPayload = { alert, pid: process.pid }
  if (session) {
    payload.session = session
  }

  const encoded = Buffer.from(JSON.stringify(payload), "utf8").toString("base64")
  process.stdout.write(`\x1b]1337;SetUserVar=WEZTERM_AGENT_ALERT=${encoded}\x1b\\`)
}

export default Plugin.define({
  id: "wezterm-agent-alert.tui",
  setup(context) {
    const titleFor = (sessionID: string | undefined): string | undefined => {
      if (!sessionID) return undefined
      const title = context.data.session.get(sessionID)?.title?.trim()
      return title || sessionID.slice(0, 8)
    }

    const isChild = (sessionID: string | undefined): boolean => {
      if (!sessionID) return false
      const session = context.data.session.get(sessionID)
      if (session) return Boolean(session.parentID)
      return context.data.session.root(sessionID) !== sessionID
    }

    const stopDone = context.data.on("session.execution.succeeded", (event) => {
      const sessionID = event.data.sessionID
      if (isChild(sessionID)) return
      signalWezTerm("opencode_done", titleFor(sessionID))
    })
    const stopPermission = context.data.on("permission.asked", (event) => {
      signalWezTerm("opencode_permission", titleFor(event.data.sessionID))
    })

    return () => {
      stopDone()
      stopPermission()
    }
  },
})
