import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "log", "modeLabel", "statusText", "submitButton", "context", "notificationButton"]
  static values = { defaultMode: String, endpoint: String, pushSubscriptionsEndpoint: String, vapidPublicKey: String }

  connect() {
    const savedMode = localStorage.getItem("jibun_os_mode") || this.defaultModeValue
    this.applyMode(savedMode, false)
    this.refreshNotificationButton()
    this.restorePushSubscriptionIfNeeded()
    this.scrollLogToBottom()

    if (this.hasInputTarget) {
      this.submitShortcutHandler = (event) => {
        if ((event.metaKey || event.ctrlKey) && event.key === "Enter") {
          event.preventDefault()
          this.inputTarget.form?.requestSubmit()
        }
      }
      this.inputTarget.addEventListener("keydown", this.submitShortcutHandler)
    }
  }

  disconnect() {
    if (this.hasInputTarget && this.submitShortcutHandler) {
      this.inputTarget.removeEventListener("keydown", this.submitShortcutHandler)
    }
  }

  setMode(event) {
    const mode = event.params.mode
    this.appendLine("YOU", `調整: ${this.labelFor(mode)}`)
    this.applyMode(mode)
  }

  insertPrompt(event) {
    const prompt = event.params.prompt
    if (!prompt || !this.hasInputTarget) return

    this.inputTarget.value = prompt
    this.inputTarget.focus()
    this.inputTarget.setSelectionRange(this.inputTarget.value.length, this.inputTarget.value.length)
  }

  async enableNotifications() {
    if (!this.notificationsSupported()) return

    if (Notification.permission === "denied") {
      this.statusTextTarget.textContent = "通知がブラウザ側でブロックされています。Safari/設定から許可してください。"
      this.refreshNotificationButton()
      return
    }

    const permission = Notification.permission === "granted" ? "granted" : await Notification.requestPermission()
    if (permission !== "granted") {
      localStorage.removeItem("jibun_os_ai_notify")
      this.statusTextTarget.textContent = "通知はOFFのままです。返信はこの画面に表示されます。"
      this.refreshNotificationButton()
      return
    }

    if (this.pushNotificationsSupported()) {
      const subscribed = await this.enablePushNotifications()
      if (subscribed) {
        localStorage.setItem("jibun_os_ai_notify", "push")
        this.statusTextTarget.textContent = "ロック中でもAI返信通知が届くようにしました。"
      } else {
        localStorage.removeItem("jibun_os_ai_notify")
        this.statusTextTarget.textContent = "通知許可はありますが、ロック中通知の登録に失敗しました。もう一度ONにしてください。"
      }
    } else {
      localStorage.setItem("jibun_os_ai_notify", "local")
      this.statusTextTarget.textContent = "この画面を開いている間、返信完了時に通知します。ロック中通知はPWA/サーバーPush対応時に使えます。"
    }

    this.refreshNotificationButton()
  }

  async send(event) {
    event.preventDefault()

    const text = this.inputTarget.value.trim()
    if (!text) return

    const mode = this.modeFromText(text)
    this.appendLine("YOU", text)
    this.inputTarget.value = ""
    this.applyMode(mode, false)
    await this.sendToHermes(text, mode)
  }

  applyMode(mode, announce = true) {
    document.body.dataset.aiMode = mode
    localStorage.setItem("jibun_os_mode", mode)
    this.modeLabelTarget.textContent = this.labelFor(mode)
    this.statusTextTarget.textContent = this.statusFor(mode)

    if (announce) {
      this.showThinking()
      window.setTimeout(() => {
        this.hideThinking()
        this.appendLine("OS", this.replyFor(mode))
      }, 360)
    }
  }

  modeFromText(text) {
    if (text.match(/疲|休|眠|早く帰|しんど|体力/)) return "rest"
    if (text.match(/節約|高|使いすぎ|安|予算|お金|金額/)) return "budget"
    if (text.match(/趣味|ライブ|DJ|読書|イベント|LT|予定/)) return "hobby"
    if (text.match(/ランチ|昼|店|渋谷|ごはん|飯/)) return "lunch"
    return "dashboard"
  }

  labelFor(mode) {
    return {
      rest: "体力セーブ",
      budget: "節約フォーカス",
      hobby: "趣味フォーカス",
      lunch: "ランチ探索",
      dashboard: "いつもの表示"
    }[mode] || "いつもの表示"
  }

  statusFor(mode) {
    return {
      rest: "打刻と帰宅前チェックを少し前へ出します。",
      budget: "有料列車の回数と金額を見やすくします。",
      hobby: "次の予定と最近のメモを拾いやすくします。",
      lunch: "店選びとランチ記録への導線を強めます。",
      dashboard: "全体を均等に見られる状態です。"
    }[mode] || "全体を均等に見られる状態です。"
  }

  replyFor(mode) {
    return {
      rest: "了解です。今日は無理をしない前提で、打刻と帰宅まわりを目立たせます。",
      budget: "了解です。今月の有料列車と金額を確認しやすい表示に寄せました。",
      hobby: "了解です。趣味予定とメモを拾いやすい視線に変えました。",
      lunch: "了解です。ランチ候補と記録導線を見つけやすくしました。",
      dashboard: "了解です。いつものバランスに戻しました。"
    }[mode] || "了解です。全体を整えます。"
  }

  async sendToHermes(text, mode) {
    if (!this.hasEndpointValue) return

    try {
      this.showThinking()
      const context = this.hasContextTarget ? this.contextTarget.value : ""
      const response = await fetch(this.endpointValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({ message: { body: text, mode, context } })
      })
      const payload = await response.json()
      this.hideThinking()

      if (response.ok && payload.ok) {
        const line = this.appendLine("Hermes", payload.assistant_reply || payload.message)
        if (payload.completed) {
          this.statusTextTarget.textContent = "Hermesから返信が届きました。"
          this.notifyReplyFinished(payload)
        } else if (payload.id) {
          line.dataset.status = "waiting"
          this.statusTextTarget.textContent = "Hermes Agentの返信を待っています。この画面は自動更新します。"
          this.pollReply(payload.id, line)
        }
      } else {
        this.appendLine("Hermes", payload.message || "送信に失敗しました。")
      }
    } catch (_error) {
      this.hideThinking()
      this.appendLine("Hermes", "送信に失敗しました。通信状態を確認してください。")
    }
  }

  csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }

  notificationsSupported() {
    return "Notification" in window
  }

  pushNotificationsSupported() {
    return this.notificationsSupported() && "serviceWorker" in navigator && "PushManager" in window && this.hasVapidPublicKeyValue && this.vapidPublicKeyValue.length > 0 && this.hasPushSubscriptionsEndpointValue
  }

  async enablePushNotifications() {
    try {
      const registration = await this.serviceWorkerRegistration()
      const existingSubscription = await registration.pushManager.getSubscription()
      const subscription = existingSubscription || await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(this.vapidPublicKeyValue)
      })

      const response = await fetch(this.pushSubscriptionsEndpointValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({ subscription: subscription.toJSON() })
      })

      return response.ok
    } catch (_error) {
      return false
    }
  }

  async serviceWorkerRegistration() {
    const existing = await navigator.serviceWorker.getRegistration("/")
    if (existing) return existing

    return navigator.serviceWorker.register("/service-worker", { scope: "/" })
  }

  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; i += 1) {
      outputArray[i] = rawData.charCodeAt(i)
    }

    return outputArray
  }

  notificationsEnabled() {
    return this.notificationsSupported() && Notification.permission === "granted" && ["push", "local", "enabled"].includes(localStorage.getItem("jibun_os_ai_notify"))
  }

  pushNotificationsEnabled() {
    return this.notificationsSupported() && Notification.permission === "granted" && localStorage.getItem("jibun_os_ai_notify") === "push"
  }

  async restorePushSubscriptionIfNeeded() {
    if (!this.pushNotificationsSupported() || Notification.permission !== "granted") return

    const savedState = localStorage.getItem("jibun_os_ai_notify")
    if (!["push", "enabled"].includes(savedState)) return

    const subscribed = await this.enablePushNotifications()
    if (subscribed) {
      localStorage.setItem("jibun_os_ai_notify", "push")
    } else {
      localStorage.removeItem("jibun_os_ai_notify")
    }

    this.refreshNotificationButton()
  }

  refreshNotificationButton() {
    if (!this.hasNotificationButtonTarget || !this.notificationsSupported()) return

    this.notificationButtonTarget.hidden = false

    if (this.pushNotificationsEnabled()) {
      this.notificationButtonTarget.textContent = "ロック中通知ON"
      this.notificationButtonTarget.disabled = true
    } else if (Notification.permission === "granted" && localStorage.getItem("jibun_os_ai_notify") === "local") {
      this.notificationButtonTarget.textContent = "完了通知ON"
      this.notificationButtonTarget.disabled = true
    } else if (Notification.permission === "denied") {
      this.notificationButtonTarget.textContent = "通知ブロック中"
      this.notificationButtonTarget.disabled = true
    } else {
      this.notificationButtonTarget.textContent = this.pushNotificationsSupported() ? "ロック中通知をON" : "完了通知をON"
      this.notificationButtonTarget.disabled = false
    }
  }

  notifyReplyFinished(payload = {}) {
    if (navigator.vibrate) navigator.vibrate([80, 40, 80])
    if (!this.notificationsEnabled() || this.pushNotificationsEnabled()) return

    const reply = payload.assistant_reply || payload.message || "返信が届きました。"
    const body = reply.length > 120 ? `${reply.slice(0, 117)}...` : reply

    try {
      const notification = new Notification("自分OS: AI返信が届きました", {
        body,
        tag: "jibun-os-ai-reply",
        renotify: true
      })

      notification.onclick = () => {
        window.focus()
        notification.close()
      }
    } catch (_error) {
      localStorage.removeItem("jibun_os_ai_notify")
      this.refreshNotificationButton()
    }
  }

  async pollReply(messageId, line, attempt = 0) {
    const maxAttempts = 45
    const delay = attempt < 10 ? 2000 : 5000

    if (attempt >= maxAttempts) {
      delete line.dataset.status
      this.statusTextTarget.textContent = "Hermesからの返信に時間がかかっています。少し待ってから再度確認してください。"
      this.replaceLineText(line, "返信待ちが長引いています。必要なら少し時間を置いて再送してください。")
      this.notifyReplyFinished({ assistant_reply: "返信待ちが長引いています。" })
      return
    }

    window.setTimeout(async () => {
      try {
        const response = await fetch(this.messageUrl(messageId), {
          headers: { "Accept": "application/json" }
        })
        const payload = await response.json()

        if (!response.ok || !payload.ok) {
          delete line.dataset.status
          this.statusTextTarget.textContent = "返信確認に失敗しました。"
          this.replaceLineText(line, payload.message || "返信の確認に失敗しました。")
          return
        }

        if (payload.completed) {
          delete line.dataset.status
          this.statusTextTarget.textContent = "Hermesから返信が届きました。"
          this.replaceLineText(line, payload.assistant_reply || payload.message)
          this.notifyReplyFinished(payload)
          return
        }

        if (attempt === 8) {
          this.replaceLineText(line, "Hermesがまだ考えています。返信が届くまでこの画面で待機します。")
          line.dataset.status = "waiting"
        }

        this.pollReply(messageId, line, attempt + 1)
      } catch (_error) {
        this.pollReply(messageId, line, attempt + 1)
      }
    }, delay)
  }

  messageUrl(messageId) {
    const base = this.endpointValue.replace(/\.json$/, "")
    return `${base}/${encodeURIComponent(messageId)}.json`
  }

  scrollLogToBottom() {
    if (!this.hasLogTarget) return

    window.requestAnimationFrame(() => {
      this.logTarget.scrollTop = this.logTarget.scrollHeight
    })
  }

  replaceLineText(line, text) {
    if (!line) return

    const badge = line.querySelector("span")
    line.textContent = ""
    if (badge) line.appendChild(badge)
    line.append(` ${text}`)
    this.scrollLogToBottom()
  }

  showThinking() {
    if (this.hasSubmitButtonTarget) this.submitButtonTarget.disabled = true
    const line = document.createElement("p")
    line.className = "ai-dock__message ai-dock__message--thinking"
    line.dataset.thinking = "true"
    const badge = document.createElement("span")
    badge.textContent = "Hermes"
    line.appendChild(badge)
    line.append(" 考えています")
    this.logTarget.appendChild(line)
    this.scrollLogToBottom()
  }

  hideThinking() {
    this.logTarget.querySelectorAll("[data-thinking='true']").forEach((line) => line.remove())
    if (this.hasSubmitButtonTarget) this.submitButtonTarget.disabled = false
  }

  appendLine(who, text) {
    const line = document.createElement("p")
    line.className = `ai-dock__message ai-dock__message--${who.toLowerCase()}`
    const badge = document.createElement("span")
    badge.textContent = who
    line.appendChild(badge)
    line.append(` ${text}`)
    this.logTarget.appendChild(line)
    this.scrollLogToBottom()
    return line
  }
}
