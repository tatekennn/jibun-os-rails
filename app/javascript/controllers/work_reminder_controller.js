import { Controller } from "@hotwired/stimulus"

// Manages local work-day reminder notifications from the Work page.
// These reminders run while the PWA/browser is active. Durable closed-app
// delivery still requires server-side scheduled Web Push.
export default class extends Controller {
  static targets = ["enabled", "checkInTime", "checkOutTime", "status"]
  static values = {
    checkInConfirmed: Boolean,
    checkOutConfirmed: Boolean,
    date: String
  }

  connect() {
    this.timers = []
    this.settings = this.loadSettings()
    this.applySettingsToForm()
    this.scheduleReminders()
    this.updateStatus()
  }

  disconnect() {
    this.clearTimers()
  }

  async toggle() {
    const wantsEnabled = this.enabledTarget.checked

    if (wantsEnabled) {
      if (!this.notificationsSupported()) {
        this.settings.enabled = false
        this.applySettingsToForm()
        this.updateStatus("この端末では通知に対応していません。")
        return
      }

      const permission = Notification.permission === "granted" ? "granted" : await Notification.requestPermission()
      if (permission !== "granted") {
        this.settings.enabled = false
        this.applySettingsToForm()
        this.saveSettings()
        this.updateStatus("通知が許可されていません。端末設定を確認してください。")
        return
      }
    }

    this.settings.enabled = wantsEnabled
    this.saveFromForm()
  }

  saveFromForm() {
    this.settings.checkInTime = this.normalizeTime(this.checkInTimeTarget.value, "09:30")
    this.settings.checkOutTime = this.normalizeTime(this.checkOutTimeTarget.value, "18:30")
    this.saveSettings()
    this.applySettingsToForm()
    this.scheduleReminders()
    this.updateStatus()
  }

  loadSettings() {
    const fallback = { enabled: false, checkInTime: "09:30", checkOutTime: "18:30" }

    try {
      return { ...fallback, ...JSON.parse(localStorage.getItem(this.storageKey()) || "{}") }
    } catch (_error) {
      return fallback
    }
  }

  saveSettings() {
    localStorage.setItem(this.storageKey(), JSON.stringify(this.settings))
  }

  applySettingsToForm() {
    this.enabledTarget.checked = Boolean(this.settings.enabled)
    this.checkInTimeTarget.value = this.normalizeTime(this.settings.checkInTime, "09:30")
    this.checkOutTimeTarget.value = this.normalizeTime(this.settings.checkOutTime, "18:30")
  }

  scheduleReminders() {
    this.clearTimers()

    if (!this.settings.enabled || !this.notificationsSupported() || Notification.permission !== "granted") return

    this.scheduleReminder("check_in", this.settings.checkInTime, this.checkInConfirmedValue, "出勤打刻の確認", "出勤打刻がまだなら、今のうちに確認してください。")
    this.scheduleReminder("check_out", this.settings.checkOutTime, this.checkOutConfirmedValue, "退勤打刻の確認", "退勤打刻がまだなら、帰る前に確認してください。")
  }

  scheduleReminder(kind, timeValue, alreadyConfirmed, title, body) {
    if (alreadyConfirmed || this.sentToday(kind)) return

    const delay = this.delayUntil(timeValue)
    const notify = () => {
      if (!this.sentToday(kind)) {
        this.markSent(kind)
        this.showNotification(title, body, kind)
      }
    }

    this.timers.push(window.setTimeout(notify, delay))
  }

  clearTimers() {
    this.timers.forEach((timer) => window.clearTimeout(timer))
    this.timers = []
  }

  delayUntil(timeValue) {
    const [hours, minutes] = this.normalizeTime(timeValue, "09:30").split(":").map(Number)
    const dueAt = new Date()
    dueAt.setHours(hours, minutes, 0, 0)
    return Math.max(dueAt.getTime() - Date.now(), 0)
  }

  async showNotification(title, body, kind) {
    const options = {
      body,
      tag: `jibun-os-work-${kind}-${this.dateValue}`,
      data: { url: "/work_days/today" },
      renotify: true
    }

    try {
      if ("serviceWorker" in navigator) {
        const registration = await navigator.serviceWorker.register("/service-worker", { scope: "/" })
        await registration.showNotification(`自分OS: ${title}`, options)
      } else {
        const notification = new Notification(`自分OS: ${title}`, options)
        notification.onclick = () => window.focus()
      }
    } catch (_error) {
      new Notification(`自分OS: ${title}`, options)
    }
  }

  updateStatus(message = null) {
    if (!this.hasStatusTarget) return

    if (message) {
      this.statusTarget.textContent = message
    } else if (!this.notificationsSupported()) {
      this.statusTarget.textContent = "この端末では通知に対応していません。"
    } else if (Notification.permission === "denied") {
      this.statusTarget.textContent = "通知がブロックされています。端末設定で許可してください。"
    } else if (this.settings.enabled) {
      this.statusTarget.textContent = `ON: 出勤 ${this.settings.checkInTime} / 退勤 ${this.settings.checkOutTime}`
    } else {
      this.statusTarget.textContent = "OFF: 時刻を選んでONにできます。"
    }
  }

  notificationsSupported() {
    return "Notification" in window
  }

  sentToday(kind) {
    return localStorage.getItem(this.sentKey(kind)) === this.dateValue
  }

  markSent(kind) {
    localStorage.setItem(this.sentKey(kind), this.dateValue)
  }

  sentKey(kind) {
    return `jibun_os_work_reminder_sent_${kind}`
  }

  storageKey() {
    return "jibun_os_work_reminder_settings"
  }

  normalizeTime(value, fallback) {
    return /^\d{2}:\d{2}$/.test(value || "") ? value : fallback
  }
}
