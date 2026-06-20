require "test_helper"

class HermesActionsControllerTest < ActionDispatch::IntegrationTest
  test "confirm_check_out action updates today's work day with valid token" do
    ai_message = AiMessage.create!(body: "今日の退勤して", mode: "dashboard")
    today = WorkDay.today
    today.update!(check_out_confirmed: false, check_out_confirmed_at: nil)

    post hermes_action_webhook_url(ai_message.public_id, token: ai_message.callback_token, format: :json),
      params: { action: "confirm_check_out" }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert_equal "confirm_check_out", payload["action"]
    assert WorkDay.today.check_out_confirmed?
    assert_not_nil WorkDay.today.check_out_confirmed_at
  end

  test "rejects action with invalid token" do
    ai_message = AiMessage.create!(body: "今日の退勤して", mode: "dashboard")

    post hermes_action_webhook_url(ai_message.public_id, token: "wrong", format: :json),
      params: { action: "confirm_check_out" }

    assert_response :unauthorized
  end

  test "rejects unsupported action" do
    ai_message = AiMessage.create!(body: "今日の退勤して", mode: "dashboard")

    post hermes_action_webhook_url(ai_message.public_id, token: ai_message.callback_token, format: :json),
      params: { action: "destroy_everything" }

    assert_response :unprocessable_entity
    payload = JSON.parse(response.body)
    assert_equal false, payload["ok"]
  end
end
