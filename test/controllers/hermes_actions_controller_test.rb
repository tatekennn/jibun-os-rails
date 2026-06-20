require "test_helper"

class HermesActionsControllerTest < ActionDispatch::IntegrationTest
  test "confirm_check_out action updates today's work day with valid token" do
    ai_message = AiMessage.create!(body: "今日の退勤して", mode: "dashboard")
    today = WorkDay.today
    today.update!(check_out_confirmed: false, check_out_confirmed_at: nil)

    post hermes_action_webhook_url(ai_message.public_id, token: ai_message.callback_token, format: :json),
      params: { operation: "confirm_check_out" }

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
      params: { operation: "confirm_check_out" }

    assert_response :unauthorized
  end

  test "monthly_spending_summary returns this month totals" do
    ai_message = AiMessage.create!(body: "今月いくら使った？？", mode: "dashboard")
    PaidRide.delete_all
    LunchLog.delete_all
    PaidRide.create!(used_on: Date.current, line_name: "京王ライナー", direction: "帰り", fare: 410, reason: "疲れ", fatigue_level: 4)
    PaidRide.create!(used_on: Date.current, line_name: "京王ライナー", direction: "帰り", fare: 410, reason: "疲れ", fatigue_level: 3)
    LunchLog.create!(visited_on: Date.current, shop_name: "渋谷定食", area: "渋谷", price: 980, rating: 4, crowdedness: "普通")
    PaidRide.create!(used_on: 1.month.ago.to_date, line_name: "京王ライナー", fare: 410, fatigue_level: 3)
    LunchLog.create!(visited_on: 1.month.ago.to_date, shop_name: "先月ランチ", price: 1200, rating: 3, crowdedness: "普通")

    post hermes_action_webhook_url(ai_message.public_id, token: ai_message.callback_token, format: :json),
      params: { operation: "monthly_spending_summary" }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert_equal "monthly_spending_summary", payload["action"]
    assert_equal 1800, payload["total"]
    assert_equal 2, payload.dig("paid_rides", "count")
    assert_equal 820, payload.dig("paid_rides", "total")
    assert_equal 1, payload.dig("lunch_logs", "count")
    assert_equal 980, payload.dig("lunch_logs", "total")
    assert_match "合計¥1,800", payload["message"]
  end

  test "rejects unsupported operation" do
    ai_message = AiMessage.create!(body: "今日の退勤して", mode: "dashboard")

    post hermes_action_webhook_url(ai_message.public_id, token: ai_message.callback_token, format: :json),
      params: { operation: "destroy_everything" }

    assert_response :unprocessable_entity
    payload = JSON.parse(response.body)
    assert_equal false, payload["ok"]
  end

  test "rejects reserved Rails action param and requires operation" do
    ai_message = AiMessage.create!(body: "今日の退勤して", mode: "dashboard")
    today = WorkDay.today
    today.update!(check_out_confirmed: false, check_out_confirmed_at: nil)

    post hermes_action_webhook_url(ai_message.public_id, token: ai_message.callback_token, format: :json),
      params: { action: "confirm_check_out" }

    assert_response :unprocessable_entity
    payload = JSON.parse(response.body)
    assert_equal false, payload["ok"]
    assert_not WorkDay.today.check_out_confirmed?
  end
end
