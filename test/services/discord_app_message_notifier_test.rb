require "test_helper"

class DiscordAppMessageNotifierTest < ActiveSupport::TestCase
  test "builds a message that is clearly from the Rails app" do
    request = ActionDispatch::TestRequest.create
    request.remote_addr = "127.0.0.1"

    content = DiscordAppMessageNotifier.build_content(
      body: "編集ボタンをもっと押しやすくしたい",
      mode: "dashboard",
      request: request
    )

    assert_includes content, "自分OSアプリ経由"
    assert_includes content, "編集ボタンをもっと押しやすくしたい"
    assert_includes content, "mode: dashboard"
    assert_includes content, "このDiscordスレッドに届いた文章は、アプリ内AIチャットから送られた通常投稿です。"
    assert_includes content, "以降はこのスレッドでそのまま返答します。"
  end

  test "includes app context when provided" do
    content = DiscordAppMessageNotifier.build_content(
      body: "全体を見て",
      mode: "dashboard",
      request: nil,
      context: "READMEを読み、git statusを確認する"
    )

    assert_includes content, "App context"
    assert_includes content, "READMEを読み、git statusを確認する"
  end

  test "builds webhook payload with a clear app display name" do
    payload = DiscordAppMessageNotifier.build_payload(body: "こんにちは", mode: "dashboard", request: nil)

    assert_equal "たてけん via 自分OS", payload[:username]
    assert_equal({ parse: [] }, payload[:allowed_mentions])
    assert_includes payload[:content], "こんにちは"
  end

  test "truncates overly long discord content" do
    content = DiscordAppMessageNotifier.build_content(body: "あ" * 3_000, mode: "dashboard", request: nil)

    assert content.length <= DiscordAppMessageNotifier::MAX_CONTENT_LENGTH
    assert_includes content, "長文のため省略"
  end

  test "builds webhook uri with discord thread id when configured" do
    original_webhook_url = DiscordAppMessageNotifier.method(:webhook_url)
    original_thread_id = DiscordAppMessageNotifier.method(:thread_id)
    DiscordAppMessageNotifier.define_singleton_method(:webhook_url) { "https://discord.com/api/webhooks/123/token?wait=true" }
    DiscordAppMessageNotifier.define_singleton_method(:thread_id) { "1517816194504065045" }

    uri = DiscordAppMessageNotifier.webhook_uri

    assert_equal "https", uri.scheme
    assert_equal "discord.com", uri.host
    assert_includes uri.query, "wait=true"
    assert_includes uri.query, "thread_id=1517816194504065045"
  ensure
    DiscordAppMessageNotifier.define_singleton_method(:webhook_url, original_webhook_url) if original_webhook_url
    DiscordAppMessageNotifier.define_singleton_method(:thread_id, original_thread_id) if original_thread_id
  end

  test "does not post when webhook url is blank" do
    original_webhook_url = DiscordAppMessageNotifier.method(:webhook_url)
    DiscordAppMessageNotifier.define_singleton_method(:webhook_url) { "" }

    assert_equal :skipped, DiscordAppMessageNotifier.call(body: "test", mode: "dashboard", request: nil, context: nil)
  ensure
    DiscordAppMessageNotifier.define_singleton_method(:webhook_url, original_webhook_url) if original_webhook_url
  end
end
