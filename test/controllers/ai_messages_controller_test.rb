require "test_helper"

class AiMessagesControllerTest < ActionDispatch::IntegrationTest
  test "requires login" do
    post ai_messages_url, params: { message: { body: "UIをもう少し落ち着かせたい", mode: "dashboard" } }

    assert_redirected_to login_url
  end

  test "signed in owner can forward app message to discord and hermes" do
    sign_in_as_owner

    discord_delivered = []
    hermes_delivered = []
    original_discord_call = DiscordAppMessageNotifier.method(:call)
    original_hermes_call = HermesAppMessageNotifier.method(:call)
    DiscordAppMessageNotifier.define_singleton_method(:call) do |body:, mode:, request:|
      discord_delivered << { body: body, mode: mode, request: request }
    end
    HermesAppMessageNotifier.define_singleton_method(:call) do |body:, mode:, request:, context: nil, ai_message: nil|
      hermes_delivered << { body: body, mode: mode, request: request, context: context, ai_message: ai_message }
      :delivered
    end

    post ai_messages_url(format: :json), params: { message: { body: "ランチ入力をもっと楽にしたい", mode: "lunch" } }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert payload["id"].present?
    assert_equal "delivered", payload["status"]
    assert_equal false, payload["completed"]
    assert_equal "DiscordとHermesへ送信しました。", payload["message"]
    assert_match "実行結果が戻るまで", payload["assistant_reply"]
    assert_equal 1, discord_delivered.size
    assert_equal "ランチ入力をもっと楽にしたい", discord_delivered.first[:body]
    assert_equal "lunch", discord_delivered.first[:mode]
    assert_equal 1, hermes_delivered.size
    assert_equal "ランチ入力をもっと楽にしたい", hermes_delivered.first[:body]
    assert_equal "lunch", hermes_delivered.first[:mode]
    assert_kind_of AiMessage, hermes_delivered.first[:ai_message]
  ensure
    DiscordAppMessageNotifier.define_singleton_method(:call, original_discord_call) if original_discord_call
    HermesAppMessageNotifier.define_singleton_method(:call, original_hermes_call) if original_hermes_call
  end

  test "signed in owner forwards today's check out request to discord and hermes" do
    sign_in_as_owner
    today = WorkDay.today
    today.update!(check_out_confirmed: false, check_out_confirmed_at: nil)

    discord_delivered = []
    hermes_delivered = []
    original_discord_call = DiscordAppMessageNotifier.method(:call)
    original_hermes_call = HermesAppMessageNotifier.method(:call)
    DiscordAppMessageNotifier.define_singleton_method(:call) do |body:, mode:, request:|
      discord_delivered << { body: body, mode: mode, request: request }
    end
    HermesAppMessageNotifier.define_singleton_method(:call) do |body:, mode:, request:, context: nil, ai_message: nil|
      hermes_delivered << { body: body, mode: mode, request: request, context: context, ai_message: ai_message }
      :delivered
    end

    post ai_messages_url(format: :json), params: { message: { body: "今日の退勤して", mode: "dashboard" } }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert_equal "delivered", payload["status"]
    assert_equal false, payload["completed"]
    assert_match "実行結果が戻るまで", payload["assistant_reply"]
    assert_not WorkDay.today.check_out_confirmed?
    assert_nil WorkDay.today.check_out_confirmed_at
    assert_equal 1, discord_delivered.size
    assert_equal "今日の退勤して", discord_delivered.first[:body]
    assert_equal 1, hermes_delivered.size
    assert_equal "今日の退勤して", hermes_delivered.first[:body]
    assert_kind_of AiMessage, hermes_delivered.first[:ai_message]
  ensure
    DiscordAppMessageNotifier.define_singleton_method(:call, original_discord_call) if original_discord_call
    HermesAppMessageNotifier.define_singleton_method(:call, original_hermes_call) if original_hermes_call
  end

  test "signed in owner forwards this month spending question to discord and hermes" do
    sign_in_as_owner

    discord_delivered = []
    hermes_delivered = []
    original_discord_call = DiscordAppMessageNotifier.method(:call)
    original_hermes_call = HermesAppMessageNotifier.method(:call)
    DiscordAppMessageNotifier.define_singleton_method(:call) do |body:, mode:, request:|
      discord_delivered << { body: body, mode: mode, request: request }
    end
    HermesAppMessageNotifier.define_singleton_method(:call) do |body:, mode:, request:, context: nil, ai_message: nil|
      hermes_delivered << { body: body, mode: mode, request: request, context: context, ai_message: ai_message }
      :delivered
    end

    post ai_messages_url(format: :json), params: { message: { body: "今月いくら使った？？", mode: "budget" } }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert_equal "delivered", payload["status"]
    assert_equal false, payload["completed"]
    assert_match "実行結果が戻るまで", payload["assistant_reply"]
    assert_equal 1, discord_delivered.size
    assert_equal "今月いくら使った？？", discord_delivered.first[:body]
    assert_equal 1, hermes_delivered.size
    assert_equal "今月いくら使った？？", hermes_delivered.first[:body]
    assert_equal "budget", hermes_delivered.first[:mode]
  ensure
    DiscordAppMessageNotifier.define_singleton_method(:call, original_discord_call) if original_discord_call
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
