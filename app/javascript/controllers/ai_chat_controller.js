import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "log", "modeLabel", "statusText", "submitButton", "context"]
  static values = { defaultMode: String, endpoint: String }

  connect() {
    const savedMode = localStorage.getItem("jibun_os_mode") || this.defaultModeValue
    this.applyMode(savedMode, false)

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

  async pollReply(messageId, line, attempt = 0) {
    const maxAttempts = 45
    const delay = attempt < 10 ? 2000 : 5000

    if (attempt >= maxAttempts) {
      delete line.dataset.status
      this.statusTextTarget.textContent = "Hermesからの返信に時間がかかっています。少し待ってから再度確認してください。"
      this.replaceLineText(line, "返信待ちが長引いています。必要なら少し時間を置いて再送してください。")
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

  replaceLineText(line, text) {
    if (!line) return

    const badge = line.querySelector("span")
    line.textContent = ""
    if (badge) line.appendChild(badge)
    line.append(` ${text}`)
    this.logTarget.scrollTop = this.logTarget.scrollHeight
  }

  showThinking() {
    if (this.hasSubmitButtonTarget) this.submitButtonTarget.disabled = true
    const line = document.createElement("p")
    line.className = "ai-dock__message ai-dock__message--thinking"
    line.dataset.thinking = "true"
    const badge = document.createElement("span")
    badge.textContent = "Hermes"
    line.appendChild(badge)
    line.append(" 考えています…")
    this.logTarget.appendChild(line)
    this.logTarget.scrollTop = this.logTarget.scrollHeight
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
    this.logTarget.scrollTop = this.logTarget.scrollHeight
    return line
  }
}
