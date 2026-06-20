require "test_helper"

class HermesRepliesControllerTest < ActionDispatch::IntegrationTest
  test "accepts valid hermes callback and completes ai message without login" do
    ai_message = AiMessage.create!(body: "今日のランチログを探して", mode: "lunch")

    post hermes_reply_webhook_url(ai_message.public_id, token: ai_message.callback_token),
      params: { reply: "渋谷ランチログを確認しました。" }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert_equal "completed", payload["status"]
    assert_equal "渋谷ランチログを確認しました。", ai_message.reload.assistant_reply
    assert ai_message.completed_at.present?
  end

  test "rejects invalid callback token" do
    ai_message = AiMessage.create!(body: "今日のランチログを探して", mode: "lunch")

    post hermes_reply_webhook_url(ai_message.public_id, token: "wrong"),
      params: { reply: "これは反映されない" }

    assert_response :unauthorized
    assert_nil ai_message.reload.assistant_reply
  end

  test "marks message failed when hermes returns error" do
    ai_message = AiMessage.create!(body: "壊れている箇所を調べて", mode: "dashboard")

    post hermes_reply_webhook_url(ai_message.public_id, token: ai_message.callback_token),
      params: { error: "テスト実行に失敗しました。" }

    assert_response :success
    assert_equal "failed", ai_message.reload.status
    assert_equal "テスト実行に失敗しました。", ai_message.error_message
  end
end
