require "json"

class PushNotificationDelivery
  def self.ai_reply_finished!(ai_message)
    new.ai_reply_finished!(ai_message)
  end

  def ai_reply_finished!(ai_message)
    return unless configured?

    payload = {
      title: "自分OS: AI返信が届きました",
      body: truncate(ai_message.conversation_reply.presence || "返信が届きました。", 120),
      url: "/ai_chat",
      tag: "jibun-os-ai-reply"
    }.to_json

    PushSubscription.active.find_each do |subscription|
      deliver(subscription, payload)
    end
  end

  private

  def configured?
    ENV["VAPID_PUBLIC_KEY"].present? && ENV["VAPID_PRIVATE_KEY"].present?
  end

  def deliver(subscription, payload)
    Webpush.payload_send(
      message: payload,
      endpoint: subscription.endpoint,
      p256dh: subscription.p256dh_key,
      auth: subscription.auth_key,
      vapid: {
        subject: ENV.fetch("VAPID_SUBJECT", "mailto:admin@example.com"),
        public_key: ENV.fetch("VAPID_PUBLIC_KEY"),
        private_key: ENV.fetch("VAPID_PRIVATE_KEY")
      }
    )
    subscription.mark_delivered!
  rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription
    subscription.destroy
  rescue Webpush::ResponseError => error
    if error.response&.code.to_i.in?([404, 410])
      subscription.destroy
    else
      Rails.logger.warn("Web push delivery failed: #{error.class}: #{error.message}")
      subscription.mark_failed!
    end
  rescue StandardError => error
    Rails.logger.warn("Web push delivery failed: #{error.class}: #{error.message}")
    subscription.mark_failed!
  end

  def truncate(text, max_length)
    text = text.to_s.strip
    return text if text.length <= max_length

    "#{text[0...(max_length - 1)]}…"
  end
end
