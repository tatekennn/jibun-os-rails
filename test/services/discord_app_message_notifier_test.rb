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
    assert_includes content, "このDiscordに届いた文章は、アプリ内AIチャットから送られた改善依頼です。"
  end

  test "does not post when webhook url is blank" do
    original_webhook_url = DiscordAppMessageNotifier.method(:webhook_url)
    DiscordAppMessageNotifier.define_singleton_method(:webhook_url) { "" }

    assert_equal :skipped, DiscordAppMessageNotifier.call(body: "test", mode: "dashboard", request: nil)
  ensure
    DiscordAppMessageNotifier.define_singleton_method(:webhook_url, original_webhook_url) if original_webhook_url
  end
end
