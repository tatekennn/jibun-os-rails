require "test_helper"

class HermesAppMessageNotifierTest < ActiveSupport::TestCase
  test "builds payload for app-originated ai message" do
    request = ActionDispatch::TestRequest.create
    request.remote_addr = "127.0.0.1"
    request.set_header("HTTP_USER_AGENT", "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Version/17.0 Mobile/15E148 Safari/604.1")
    request.set_header("HTTP_REFERER", "https://jibun-os.onrender.com/ai_chat")

    ai_message = AiMessage.create!(body: "退勤チェックして今日のまとめを見たい", mode: "dashboard")

    previous_message = AiMessage.create!(body: "昨日の退勤どうだった？", mode: "dashboard")
    previous_message.complete!(reply: "昨日は退勤確認済みです。")

    payload = HermesAppMessageNotifier.build_payload(
      body: "退勤チェックして今日のまとめを見たい",
      mode: "dashboard",
      request: request,
      ai_message: ai_message,
      conversation_history: [previous_message]
    )

    assert_equal "jibun_os.ai_message", payload[:event_type]
    assert_equal "jibun-os-rails", payload[:app]
    assert_equal "自分OSアプリ", payload[:source]
    assert_equal "退勤チェックして今日のまとめを見たい", payload[:body]
    assert_equal "dashboard", payload[:mode]
    assert_equal "/", payload[:path]
    assert_equal "https://jibun-os.onrender.com/ai_chat", payload[:referer]
    assert_includes payload[:user_agent], "iPhone"
    assert_includes payload[:client_hint], "mobile"
    assert_includes payload[:client_hint], "pwa_candidate"
    assert_includes payload[:client_hint], "safari"
    assert_includes payload[:context], "tatekennn/jibun-os-rails"
    assert_includes payload[:context], "Render Web Service jibun-os"
    assert_includes payload[:context], "必ずcallback_urlへJSONでPOST"
    assert_includes payload[:context], "Discordだけに返して終わらない"
    assert_includes payload[:context], "短文・曖昧な依頼はmodeと本文から意図を補って処理"
    assert_includes payload[:context], "callback送信時は汎用terminal/python/curl"
    assert_includes payload[:context], "action_urlへ {\"operation\":\"confirm_check_out\"}"
    assert_includes payload[:context], "生活データ操作はRailsのaction_url経由"
    assert_includes payload[:context], "--- recent conversation history: last 5 rallies ---"
    assert_includes payload[:context], "[1] mode=dashboard"
    assert_includes payload[:context], "User: 昨日の退勤どうだった？"
    assert_includes payload[:context], "Hermes: 昨日は退勤確認済みです。"
    assert_equal ai_message.public_id, payload[:message_id]
    assert_includes payload[:callback_url], ai_message.public_id
    assert_includes payload[:callback_url], ai_message.callback_token
    assert_includes payload[:action_url], ai_message.public_id
    assert_includes payload[:action_url], ai_message.callback_token
    assert payload[:sent_at].present?
  end

  test "adds generic hmac signature header when secret is configured" do
    original_secret = HermesAppMessageNotifier.method(:webhook_secret)
    HermesAppMessageNotifier.define_singleton_method(:webhook_secret) { "test-secret" }
    json_body = { event_type: "jibun_os.ai_message", body: "test" }.to_json

    headers = HermesAppMessageNotifier.headers_for(json_body)

    assert_equal "application/json", headers["Content-Type"]
    assert_equal OpenSSL::HMAC.hexdigest("SHA256", "test-secret", json_body), headers["X-Webhook-Signature"]
    assert headers["X-Request-ID"].present?
  ensure
    HermesAppMessageNotifier.define_singleton_method(:webhook_secret, original_secret) if original_secret
  end

  test "does not post when webhook url is blank" do
    original_webhook_url = HermesAppMessageNotifier.method(:webhook_url)
    HermesAppMessageNotifier.define_singleton_method(:webhook_url) { "" }

    assert_equal :skipped, HermesAppMessageNotifier.call(body: "test", mode: "dashboard", request: nil)
  ensure
    HermesAppMessageNotifier.define_singleton_method(:webhook_url, original_webhook_url) if original_webhook_url
  end
end
