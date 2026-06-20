require "json"
require "net/http"
require "openssl"
require "securerandom"
require "uri"

class HermesAppMessageNotifier
  class DeliveryError < StandardError; end

  class << self
    def call(body:, mode:, request:, context: nil, ai_message: nil)
      return :skipped if webhook_url.blank?

      json_body = build_payload(body: body, mode: mode, request: request, context: context, ai_message: ai_message).to_json
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

    def build_payload(body:, mode:, request:, context: nil, ai_message: nil)
      {
        event_type: "jibun_os.ai_message",
        app: "jibun-os-rails",
        source: "自分OSアプリ",
        body: body.to_s.strip,
        context: [default_context, context].compact_blank.join("\n\n--- app page context ---\n"),
        mode: mode.presence || "dashboard",
        path: request&.path || "unknown",
        ip: request&.remote_ip || "unknown",
        message_id: ai_message&.public_id,
        callback_url: callback_url_for(request: request, ai_message: ai_message),
        action_url: action_url_for(request: request, ai_message: ai_message),
        sent_at: Time.current.iso8601
      }.compact
    end

    def default_context
      <<~CONTEXT.squish
        自分OSRailsアプリからの依頼です。GitHub repoはtatekennn/jibun-os-rails、作業ディレクトリは/opt/data/jibun-os-railsです。
        本命はRails版で、mainへpushするとRender Web Service jibun-osへ自動デプロイされます。
        作業時はREADME.md、git status、関連ファイルを確認し、必要なら検索・コード変更・テスト・commit・pushまで進めます。
        config/master.keyなどの秘密情報は絶対にGitHubへ入れません。
        アプリ内チャットでは特定の人格設定やsoul.mdは前提にしません。
        重要: 最終的なアプリ表示用返信は必ずcallback_urlへJSONでPOSTしてください。成功時は {"reply":"ユーザーに表示する最終返信"}、失敗時は {"error":"ユーザーに表示するエラー"} を送ります。
        打刻確認や月次支出集計などRailsアプリ内データの操作・参照が必要な場合だけ、action_urlへ {"operation":"confirm_check_out"} のように許可済みoperationをJSONでPOSTし、その結果を要約してcallback_urlへ返してください。任意URLや任意SQLは使いません。
      CONTEXT
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
