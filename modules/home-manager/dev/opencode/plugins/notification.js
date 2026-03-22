const PAPLAY_COMMAND = "__PAPLAY_COMMAND__"
const NOTIFICATION_SOUND = "__NOTIFICATION_SOUND__"

const shouldPlayNotification = (event) =>
  (event.type === "session.status" && event.properties?.status?.type === "idle") || event.type === "session.error"

export const NotificationPlugin = async ({ $ }) => {
  const playNotification = async () => {
    await $`${PAPLAY_COMMAND} ${NOTIFICATION_SOUND} 2>/dev/null || true`
  }

  return {
    event: async ({ event }) => {
      if (shouldPlayNotification(event)) {
        await playNotification()
      }
    },
  }
}
