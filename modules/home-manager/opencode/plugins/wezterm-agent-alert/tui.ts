import fs from "node:fs"
import os from "node:os"
import path from "node:path"
import { randomUUID } from "node:crypto"
import { Plugin } from "@opencode/plugin/tui"

type Alert = "opencode_done" | "opencode_permission"

type PendingAlert = {
  alert: Alert
  owner?: string
  pane: string
  pid: number
  session?: string
  updated: number
}

const stateDir = process.env.XDG_RUNTIME_DIR || path.join(os.homedir(), ".cache")
const pendingDir = path.join(stateDir, "wezterm-agent-pending")
const ownerDir = path.join(stateDir, "wezterm-agent-owners")

function ensureDirs(): void {
  fs.mkdirSync(pendingDir, { recursive: true, mode: 0o700 })
  fs.mkdirSync(ownerDir, { recursive: true, mode: 0o700 })
}

function writeJsonAtomic(dir: string, name: string, value: unknown): void {
  try {
    ensureDirs()
    const tmp = path.join(dir, `.${name}.tmp`)
    const file = path.join(dir, name)
    fs.writeFileSync(tmp, JSON.stringify(value))
    fs.renameSync(tmp, file)
  } catch {
    // Alert delivery is best-effort; never break the TUI over it.
  }
}

function readOwners(): Map<string, string> {
  const owners = new Map<string, { pane: string; updated: number }>()
  try {
    for (const name of fs.readdirSync(ownerDir)) {
      if (!name.endsWith(".json") || name.startsWith(".")) continue
      try {
        const data = JSON.parse(fs.readFileSync(path.join(ownerDir, name), "utf8"))
        if (typeof data?.session !== "string" || typeof data?.pane !== "string") continue
        const updated = typeof data.updated === "number" ? data.updated : 0
        const current = owners.get(data.session)
        if (!current || updated > current.updated) {
          owners.set(data.session, { pane: data.pane, updated })
        }
      } catch {
        // Ignore stale/corrupt owner records.
      }
    }
  } catch {
    // Owner directory has not been created yet.
  }
  return new Map([...owners].map(([session, value]) => [session, value.pane]))
}

function claimSession(sessionID: string): void {
  const pane = process.env.WEZTERM_PANE
  if (!pane) return
  writeJsonAtomic(ownerDir, `${pane}-${sessionID}.json`, {
    session: sessionID,
    pane,
    updated: Date.now(),
  })
}

function queueAlert(alert: Alert, session?: string, owner?: string, active?: boolean): void {
  const pane = process.env.WEZTERM_PANE
  if (!pane) return

  if (owner) {
    const owners = readOwners()
    if (active) {
      // The TUI currently showing the session takes ownership.
      claimSession(owner)
    } else if (owners.get(owner) !== pane) {
      // Another pane owns this session; ignore this TUI's copy of the event.
      return
    }
  }

  const payload: PendingAlert = {
    alert,
    pane,
    pid: process.pid,
    updated: Date.now(),
  }
  if (session) {
    payload.session = session
  }
  if (owner) {
    payload.owner = owner
  }
  writeJsonAtomic(pendingDir, `${pane}-${Date.now()}-${randomUUID()}.json`, payload)
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

    const rootFor = (sessionID: string): string => context.data.session.root(sessionID)

    const activeSessionID = (): string | undefined => {
      const route = context.ui.router.current()
      return route?.type === "session" ? route.sessionID : undefined
    }

    const activeRootID = (): string | undefined => {
      const sessionID = activeSessionID()
      return sessionID ? rootFor(sessionID) : undefined
    }

    const inActiveSessionFamily = (sessionID: string | undefined): boolean => {
      if (!sessionID) return false
      const active = activeRootID()
      return active !== undefined && rootFor(sessionID) === active
    }

    // The shared OpenCode server delivers every session's events to every TUI.
    // Claim the session this pane is working on so the alert queue can route
    // completions back to the right pane even after the TUI switches away or
    // the pane loses focus.
    const initial = activeSessionID()
    if (initial) claimSession(rootFor(initial))

    const stopStarted = context.data.on("session.execution.started", (event) => {
      const sessionID = event.data.sessionID
      if (!sessionID) return
      if (!inActiveSessionFamily(sessionID)) return
      claimSession(rootFor(sessionID))
    })

    const stopDone = context.data.on("session.execution.succeeded", (event) => {
      const sessionID = event.data.sessionID
      if (!sessionID) return
      if (isChild(sessionID)) return
      queueAlert(
        "opencode_done",
        titleFor(sessionID),
        rootFor(sessionID),
        sessionID === activeSessionID(),
      )
    })

    const stopPermission = context.data.on("permission.asked", (event) => {
      const sessionID = event.data.sessionID
      if (!sessionID) return
      queueAlert(
        "opencode_permission",
        titleFor(sessionID),
        rootFor(sessionID),
        inActiveSessionFamily(sessionID),
      )
    })

    return () => {
      stopStarted()
      stopDone()
      stopPermission()
    }
  },
})
