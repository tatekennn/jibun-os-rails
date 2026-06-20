require "json"
require "net/http"
require "uri"

class DiscordAppMessageNotifier
  class DeliveryError < StandardError; end

  class << self
    def call(body:, mode:, request:)
      return :skipped if webhook_url.blank?

      uri = webhook_uri
      response = Net::HTTP.post(
        uri,
        { content: build_content(body: body, mode: mode, request: request) }.to_json,
        "Content-Type" => "application/json"
      )

      return :delivered if response.is_a?(Net::HTTPSuccess)

      raise DeliveryError, "Discord webhook returned #{response.code}"
    rescue URI::InvalidURIError, SocketError, Timeout::Error, Errno::ECONNREFUSED => error
      raise DeliveryError, error.message
    end

    def build_content(body:, mode:, request:)
      <<~MESSAGE.strip
        📨 **自分OSアプリ経由のAIチャット投稿**
        このDiscordに届いた文章は、アプリ内AIチャットから送られた改善依頼です。

        ```
        #{body.to_s.strip}
        ```

        - mode: #{mode.presence || "dashboard"}
        - path: #{request&.path || "unknown"}
        - ip: #{request&.remote_ip || "unknown"}
        - sent_at: #{Time.current.strftime("%Y-%m-%d %H:%M:%S %Z")}
      MESSAGE
    end

    def webhook_uri
      uri = URI.parse(webhook_url)
      return uri if thread_id.blank?

      query = URI.decode_www_form(uri.query.to_s)
      query.reject! { |key, _value| key == "thread_id" }
      query << ["thread_id", thread_id]
      uri.query = URI.encode_www_form(query)
      uri
    end

    def thread_id
      ENV["DISCORD_APP_MESSAGE_THREAD_ID"]
    end

    def webhook_url
      ENV["DISCORD_APP_MESSAGE_WEBHOOK_URL"]
    end
  end
end
