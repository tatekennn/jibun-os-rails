require "json"
require "net/http"
require "openssl"
require "securerandom"
require "uri"

class HermesAppMessageNotifier
  class DeliveryError < StandardError; end

  class << self
    def call(body:, mode:, request:, context: nil, ai_message: nil, conversation_history: [])
      return :skipped if webhook_url.blank?

      json_body = build_payload(body: body, mode: mode, request: request, context: context, ai_message: ai_message, conversation_history: conversation_history).to_json
      response = Net::HTTP.post(
        webhook_uri,
        json_body,
        headers_for(json_body)
      )

      return :delivered if response.is_a?(Net::HTTPSuccess)

      raise DeliveryError, "Hermes webhook returned #{response.code}"
    rescue URI::InvalidURIError, SocketError, Timeout::Error, Errno::ECONNREFUSED => error
      raise DeliveryError, error.message
    end

    def build_payload(body:, mode:, request:, context: nil, ai_message: nil, conversation_history: [])
      {
        event_type: "jibun_os.ai_message",
        app: "jibun-os-rails",
        source: "自分OSアプリ",
        body: body.to_s.strip,
        context: [default_context, conversation_history_context(conversation_history), context].compact_blank.join("\n\n--- app page context ---\n"),
        mode: mode.presence || "dashboard",
        path: request&.path || "unknown",
        referer: request&.referer,
        user_agent: request&.user_agent,
        client_hint: client_hint_for(request),
        ip: request&.remote_ip || "unknown",
        message_id: ai_message&.public_id,
        callback_url: callback_url_for(request: request, ai_message: ai_message),
        action_url: action_url_for(request: request, ai_message: ai_message),
        sent_at: Time.current.iso8601
      }.compact
    end

    def default_context
      <<~CONTEXT.squish
        自分OSRailsアプリからの依頼です。これはユーザーがスマホ/PWAまたはPCのアプリ内AIチャットから入力した自然文です。
        GitHub repoはtatekennn/jibun-os-rails、作業ディレクトリは/opt/data/jibun-os-railsです。
        本命はRails版で、mainへpushするとRender Web Service jibun-osへ自動デプロイされます。本番URLはhttps://jibun-os.onrender.comです。
        アプリの目的は、出勤・退勤チェック、有料列車ログ、渋谷ランチログ、趣味メモをまとめる個人用生活補助PWAです。スマホから毎日使うため、返答や提案は短く実用的にしてください。
        modeの意味: dashboard=全体/打刻/今日の整理、rest=疲労・休息、budget=有料列車/支出、hobby=趣味予定・メモ、lunch=渋谷ランチです。短文・曖昧な依頼はmodeと本文から意図を補って処理します。
        作業時はREADME.md、git status、関連ファイルを確認し、必要なら検索・コード変更・テスト・commit・pushまで進めます。Render本番反映やasset確認が必要なら可能な範囲で確認します。
        config/master.key、環境変数、callback token、Webhook URLなどの秘密情報は絶対にGitHub・Discord・最終返答へ出しません。
        アプリ内チャットでは特定の人格設定やsoul.mdは前提にしません。ユーザーには自然で簡潔に、作業結果・確認結果・次に必要なことを返します。
        重要: 最終的なアプリ表示用返信は必ずcallback_urlへJSONでPOSTしてください。成功時は {"reply":"ユーザーに表示する最終返信"}、失敗時は {"error":"ユーザーに表示するエラー"} を送ります。Discordだけに返して終わらないでください。
        callback送信時は汎用terminal/python/curlのコマンド本文に日本語や全角記号を直接埋め込まないでください。承認に止まる場合があるため、必要ならJSON本文をunicode escape等のASCII-safeな形にします。
        打刻確認や月次支出集計などRailsアプリ内データの操作・参照が必要な場合だけ、action_urlへ {"operation":"confirm_check_out"} のように許可済みoperationをJSONでPOSTし、その結果を要約してcallback_urlへ返してください。任意URLや任意SQLは使いません。
        生活データ操作はRailsのaction_url経由を優先し、DBを直接乱暴に書き換えないでください。コード変更が必要な開発依頼と、日常ログ操作の依頼を区別してください。
      CONTEXT
    end

    def conversation_history_context(conversation_history)
      messages = Array(conversation_history).first(5)
      return if messages.blank?

      lines = ["--- recent conversation history: last 5 rallies ---"]
      messages.each_with_index do |message, index|
        lines << "[#{index + 1}] mode=#{message.mode} at=#{message.created_at&.iso8601}"
        lines << "User: #{message.body.to_s.strip}"
        lines << "Hermes: #{message.conversation_reply.to_s.strip}"
      end
      lines.join("\n")
    end

    def client_hint_for(request)
      return "unknown" if request.blank?

      user_agent = request.user_agent.to_s.downcase
      hints = []
      hints << "mobile" if user_agent.match?(/iphone|android|mobile/)
      hints << "pwa_candidate" if request.referer.to_s.include?("/ai_chat") || request.path.to_s.include?("ai_messages")
      hints << "safari" if user_agent.include?("safari") && !user_agent.include?("chrome")
      hints << "chrome" if user_agent.include?("chrome") || user_agent.include?("crios")
      hints.presence&.join(", ") || "desktop_or_unknown"
    end

    def callback_url_for(request:, ai_message:)
      return if request.blank? || ai_message.blank?

      Rails.application.routes.url_helpers.hermes_reply_webhook_url(
        ai_message.public_id,
        token: ai_message.callback_token,
        host: request.host,
        protocol: request.protocol
      )
    end

    def action_url_for(request:, ai_message:)
      return if request.blank? || ai_message.blank?

      Rails.application.routes.url_helpers.hermes_action_webhook_url(
        ai_message.public_id,
        token: ai_message.callback_token,
        host: request.host,
        protocol: request.protocol
      )
    end

    def headers_for(json_body)
      headers = {
        "Content-Type" => "application/json",
        "X-Request-ID" => SecureRandom.uuid
      }

      if webhook_secret.present?
        headers["X-Webhook-Signature"] = OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, json_body)
      end

      headers
    end

    def webhook_uri
      URI.parse(webhook_url)
    end

    def webhook_url
      ENV["HERMES_APP_MESSAGE_WEBHOOK_URL"]
    end

    def webhook_secret
      ENV["HERMES_APP_MESSAGE_WEBHOOK_SECRET"]
    end
  end
end
