const PAPLAY_COMMAND = "__PAPLAY_COMMAND__"
const DUNSTIFY_COMMAND = "__DUNSTIFY_COMMAND__"
const NOTIFY_SEND_COMMAND = "__NOTIFY_SEND_COMMAND__"
const NOTIFICATION_SOUND = "__NOTIFICATION_SOUND__"

const isIdleStatusEvent = (event) => event.type === "session.status" && event.properties?.status?.type === "idle"

const isIdleEvent = (event) => event.type === "session.idle"

const getRuntimeDir = () => {
  if (process.env.XDG_RUNTIME_DIR) {
    return process.env.XDG_RUNTIME_DIR
  }

  if (typeof process.getuid === "function") {
    return `/run/user/${process.getuid()}`
  }

  if (process.env.UID) {
    return `/run/user/${process.env.UID}`
  }

  return "/run/user/1000"
}

const getDbusSessionBusAddress = (runtimeDir) =>
  process.env.DBUS_SESSION_BUS_ADDRESS || `unix:path=${runtimeDir}/bus`

const toErrorMessage = (error) => {
  if (error instanceof Error) {
    return error.message
  }

  return String(error)
}

const getNotificationContent = (event) => {
  if (event.type === "session.error") {
    return {
      body: "Session failed",
      urgency: "critical",
      summary: "OpenCode",
    }
  }

  return {
    body: "Agent finished",
    urgency: "normal",
    summary: "OpenCode",
  }
}

export const NotificationPlugin = async ({ $ }) => {
  let lastIdleSessionID = null

  const playNotification = async () => {
    try {
      await $`${PAPLAY_COMMAND} ${NOTIFICATION_SOUND}`
    } catch (_error) {
    }
  }

  const showDesktopNotification = async (event) => {
    const { summary, body, urgency } = getNotificationContent(event)
    const runtimeDir = getRuntimeDir()
    const dbusSessionBusAddress = getDbusSessionBusAddress(runtimeDir)
    let lastError = null

    try {
      await $`env XDG_RUNTIME_DIR=${runtimeDir} DBUS_SESSION_BUS_ADDRESS=${dbusSessionBusAddress} ${DUNSTIFY_COMMAND} -a opencode -u ${urgency} -- ${summary} ${body}`
      return
    } catch (error) {
      lastError = error
    }

    try {
      await $`env XDG_RUNTIME_DIR=${runtimeDir} DBUS_SESSION_BUS_ADDRESS=${dbusSessionBusAddress} ${NOTIFY_SEND_COMMAND} -a opencode -u ${urgency} ${summary} ${body}`
      return
    } catch (error) {
      lastError = error
    }

    if (lastError !== null) {
      console.error(`[NotificationPlugin] desktop notification failed: ${toErrorMessage(lastError)}`)
    }
  }

  const notify = async (event) => {
    await playNotification()
    await showDesktopNotification(event)
  }

  return {
    event: async ({ event }) => {
      if (event.type === "session.error") {
        await notify(event)
        return
      }

      if (isIdleStatusEvent(event)) {
        lastIdleSessionID = event.properties?.sessionID ?? null
        await notify(event)
        return
      }

      if (isIdleEvent(event)) {
        const sessionID = event.properties?.sessionID ?? null
        if (sessionID !== null && sessionID === lastIdleSessionID) {
          lastIdleSessionID = null
          return
        }
        await notify(event)
      }
    },
  }
}
