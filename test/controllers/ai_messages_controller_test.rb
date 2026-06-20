require "test_helper"

class AiMessagesControllerTest < ActionDispatch::IntegrationTest
  test "requires login" do
    post ai_messages_url, params: { message: { body: "UIをもう少し落ち着かせたい", mode: "dashboard" } }

    assert_redirected_to login_url
  end

  test "signed in owner forwards app message to Hermes and waits for callback" do
    sign_in_as_owner

    6.times do |index|
      message = AiMessage.create!(body: "過去の依頼#{index + 1}", mode: "dashboard", created_at: index.minutes.ago, updated_at: index.minutes.ago)
      message.complete!(reply: "過去の返信#{index + 1}")
    end

    hermes_delivered = []
    original_hermes_call = HermesAppMessageNotifier.method(:call)
    HermesAppMessageNotifier.define_singleton_method(:call) do |body:, mode:, request:, context: nil, ai_message: nil, conversation_history: []|
      hermes_delivered << { body: body, mode: mode, request: request, context: context, ai_message: ai_message, conversation_history: conversation_history }
      :delivered
    end

    post ai_messages_url(format: :json), params: { message: { body: "ランチ入力をもっと楽にしたい", mode: "lunch", context: "READMEを先に読む" } }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert payload["id"].present?
    assert_equal "delivered", payload["status"]
    assert_equal false, payload["completed"]
    assert_equal "Hermes Agentへ送信しました。返信を待っています。", payload["message"]
    assert_match "Hermes Agentへ送信しました", payload["assistant_reply"]
    assert_equal 1, hermes_delivered.size
    assert_equal "ランチ入力をもっと楽にしたい", hermes_delivered.first[:body]
    assert_equal "lunch", hermes_delivered.first[:mode]
    assert_equal "READMEを先に読む", hermes_delivered.first[:context]
    assert_equal AiMessage.last, hermes_delivered.first[:ai_message]
    assert_equal 5, hermes_delivered.first[:conversation_history].size
    assert_equal "過去の依頼5", hermes_delivered.first[:conversation_history].first.body
    assert_equal "過去の依頼1", hermes_delivered.first[:conversation_history].last.body
  ensure
    HermesAppMessageNotifier.define_singleton_method(:call, original_hermes_call) if original_hermes_call
  end

  test "signed in owner sees error when Hermes webhook is not configured" do
    sign_in_as_owner

    original_hermes_call = HermesAppMessageNotifier.method(:call)
    HermesAppMessageNotifier.define_singleton_method(:call) do |body:, mode:, request:, context: nil, ai_message: nil, conversation_history: []|
      :skipped
    end

    post ai_messages_url(format: :json), params: { message: { body: "こんにちは", mode: "dashboard" } }

    assert_response :bad_gateway
    payload = JSON.parse(response.body)
    assert_equal false, payload["ok"]
    assert_match "Hermes連携URLが未設定", payload["message"]
    assert_equal "failed", AiMessage.last.status
  ensure
    HermesAppMessageNotifier.define_singleton_method(:call, original_hermes_call) if original_hermes_call
  end

  test "signed in owner forwards today's check out request to Hermes without changing data locally" do
    sign_in_as_owner
    today = WorkDay.today
    today.update!(check_out_confirmed: false, check_out_confirmed_at: nil)

    hermes_delivered = []
    original_hermes_call = HermesAppMessageNotifier.method(:call)
    HermesAppMessageNotifier.define_singleton_method(:call) do |body:, mode:, request:, context: nil, ai_message: nil, conversation_history: []|
      hermes_delivered << { body: body, mode: mode, request: request, context: context, ai_message: ai_message, conversation_history: conversation_history }
      :delivered
    end

    post ai_messages_url(format: :json), params: { message: { body: "今日の退勤して", mode: "dashboard" } }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert_equal "delivered", payload["status"]
    assert_equal false, payload["completed"]
    assert_match "Hermes Agentへ送信しました", payload["assistant_reply"]
    assert_not WorkDay.today.check_out_confirmed?
    assert_nil WorkDay.today.check_out_confirmed_at
    assert_equal 1, hermes_delivered.size
    assert_equal "今日の退勤して", hermes_delivered.first[:body]
    assert_equal AiMessage.last, hermes_delivered.first[:ai_message]
  ensure
    HermesAppMessageNotifier.define_singleton_method(:call, original_hermes_call) if original_hermes_call
  end

  test "signed in owner forwards this month spending question to Hermes" do
    sign_in_as_owner

    hermes_delivered = []
    original_hermes_call = HermesAppMessageNotifier.method(:call)
    HermesAppMessageNotifier.define_singleton_method(:call) do |body:, mode:, request:, context: nil, ai_message: nil, conversation_history: []|
      hermes_delivered << { body: body, mode: mode, request: request, context: context, ai_message: ai_message, conversation_history: conversation_history }
      :delivered
    end

    post ai_messages_url(format: :json), params: { message: { body: "今月いくら使った？？", mode: "budget" } }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert_equal "delivered", payload["status"]
    assert_equal false, payload["completed"]
    assert_match "Hermes Agentへ送信しました", payload["assistant_reply"]
    assert_equal 1, hermes_delivered.size
    assert_equal "今月いくら使った？？", hermes_delivered.first[:body]
    assert_equal "budget", hermes_delivered.first[:mode]
    assert_equal AiMessage.last, hermes_delivered.first[:ai_message]
  ensure
    HermesAppMessageNotifier.define_singleton_method(:call, original_hermes_call) if original_hermes_call
  end

  test "shows stored assistant reply for polling" do
    sign_in_as_owner
    ai_message = AiMessage.create!(body: "今日の有料列車を見たい", mode: "budget")
    ai_message.complete!(reply: "今月の有料列車ログを確認しました。")

    get ai_message_url(ai_message.public_id, format: :json)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert_equal ai_message.public_id, payload["id"]
    assert_equal "completed", payload["status"]
    assert_equal true, payload["completed"]
    assert_equal "今月の有料列車ログを確認しました。", payload["assistant_reply"]
  end

  test "blank message is rejected" do
    sign_in_as_owner

    post ai_messages_url(format: :json), params: { message: { body: "   ", mode: "dashboard" } }

    assert_response :unprocessable_entity
    payload = JSON.parse(response.body)
    assert_equal false, payload["ok"]
  end
end
