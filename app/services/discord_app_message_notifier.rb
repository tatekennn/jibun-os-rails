require "json"
require "net/http"
require "uri"

class DiscordAppMessageNotifier
  class DeliveryError < StandardError; end
  MAX_CONTENT_LENGTH = 1_900

  class << self
    def call(body:, mode:, request:, context: nil)
      return :skipped if webhook_url.blank?

      uri = webhook_uri
      response = Net::HTTP.post(
        uri,
        build_payload(body: body, mode: mode, request: request, context: context).to_json,
        "Content-Type" => "application/json"
      )

      return :delivered if response.is_a?(Net::HTTPSuccess)

      raise DeliveryError, "Discord webhook returned #{response.code}"
    rescue URI::InvalidURIError, SocketError, Timeout::Error, Errno::ECONNREFUSED => error
      raise DeliveryError, error.message
    end

    def build_content(body:, mode:, request:, context: nil)
      content = <<~MESSAGE.strip
        📨 **自分OSアプリ経由のAIチャット投稿**
        このDiscordスレッドに届いた文章は、アプリ内AIチャットから送られた通常投稿です。
        以降はこのスレッドでそのまま返答します。

        ```
        #{body.to_s.strip}
        ```

        - mode: #{mode.presence || "dashboard"}
        - path: #{request&.path || "unknown"}
        - ip: #{request&.remote_ip || "unknown"}
        - sent_at: #{Time.current.strftime("%Y-%m-%d %H:%M:%S %Z")}
      MESSAGE

      if context.present?
        content = <<~MESSAGE.strip
          #{content}

          **App context**
          ```
          #{context.to_s.strip}
          ```
        MESSAGE
      end

      truncate_content(content)
    end

    def build_payload(body:, mode:, request:, context: nil)
      {
        username: "たてけん via 自分OS",
        allowed_mentions: { parse: [] },
        content: build_content(body: body, mode: mode, request: request, context: context)
      }
    end

    def truncate_content(content)
      return content if content.length <= MAX_CONTENT_LENGTH

      "#{content[0, MAX_CONTENT_LENGTH - 20]}\n…（長文のため省略）"
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
