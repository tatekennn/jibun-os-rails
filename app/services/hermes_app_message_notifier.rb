require "json"
require "net/http"
require "openssl"
require "securerandom"
require "uri"

class HermesAppMessageNotifier
  class DeliveryError < StandardError; end

  class << self
    def call(body:, mode:, request:)
      return :skipped if webhook_url.blank?

      json_body = build_payload(body: body, mode: mode, request: request).to_json
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

    def build_payload(body:, mode:, request:)
      {
        event_type: "jibun_os.ai_message",
        app: "jibun-os-rails",
        source: "自分OSアプリ",
        body: body.to_s.strip,
        mode: mode.presence || "dashboard",
        path: request&.path || "unknown",
        ip: request&.remote_ip || "unknown",
        sent_at: Time.current.iso8601
      }
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
