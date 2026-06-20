import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "log", "modeLabel"]
  static values = { defaultMode: String }

  connect() {
    const savedMode = localStorage.getItem("jibun_os_mode") || this.defaultModeValue
    this.applyMode(savedMode, false)
  }

  setMode(event) {
    this.applyMode(event.params.mode)
  }

  send(event) {
    event.preventDefault()

    const text = this.inputTarget.value.trim()
    if (!text) return

    const mode = this.modeFromText(text)
    this.appendLine("YOU", text)
    this.applyMode(mode)
    this.inputTarget.value = ""
  }

  applyMode(mode, announce = true) {
    document.body.dataset.aiMode = mode
    localStorage.setItem("jibun_os_mode", mode)
    this.modeLabelTarget.textContent = this.labelFor(mode)

    if (announce) {
      this.appendLine("OS", this.replyFor(mode))
    }
  }

  modeFromText(text) {
    if (text.match(/疲|休|眠|早く帰|しんど/)) return "rest"
    if (text.match(/節約|高|使いすぎ|安|予算/)) return "budget"
    if (text.match(/趣味|ライブ|DJ|読書|イベント|LT/)) return "hobby"
    if (text.match(/ランチ|昼|店|渋谷/)) return "lunch"
    return "dashboard"
  }

  labelFor(mode) {
    return {
      rest: "体力セーブ",
      budget: "節約フォーカス",
      hobby: "趣味フォーカス",
      lunch: "ランチ探索",
      dashboard: "ダッシュボード調整"
    }[mode] || "ダッシュボード調整"
  }

  replyFor(mode) {
    return {
      rest: "打刻と帰宅まわりを目立たせます。",
      budget: "列車回数と価格を強めに出します。",
      hobby: "次の予定とメモを前に出します。",
      lunch: "ランチ候補を探しやすくします。",
      dashboard: "全体をいつもの見え方に戻します。"
    }[mode] || "全体を整えます。"
  }

  appendLine(who, text) {
    const line = document.createElement("p")
    const badge = document.createElement("span")
    badge.textContent = who
    line.appendChild(badge)
    line.append(` ${text}`)
    this.logTarget.appendChild(line)
    this.logTarget.scrollTop = this.logTarget.scrollHeight
  }
}
