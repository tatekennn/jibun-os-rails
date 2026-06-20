require "test_helper"

class AiMessagesControllerTest < ActionDispatch::IntegrationTest
  test "requires login" do
    post ai_messages_url, params: { message: { body: "UIをもう少し落ち着かせたい", mode: "dashboard" } }

    assert_redirected_to login_url
  end

  test "signed in owner can forward app message to discord thread and complete locally" do
    sign_in_as_owner

    discord_delivered = []
    original_discord_call = DiscordAppMessageNotifier.method(:call)
    DiscordAppMessageNotifier.define_singleton_method(:call) do |body:, mode:, request:, context: nil|
      discord_delivered << { body: body, mode: mode, request: request, context: context }
      :delivered
    end

    post ai_messages_url(format: :json), params: { message: { body: "ランチ入力をもっと楽にしたい", mode: "lunch", context: "READMEを先に読む" } }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert payload["id"].present?
    assert_equal "completed", payload["status"]
    assert_equal true, payload["completed"]
    assert_equal "Discordスレッドへ送信しました。", payload["message"]
    assert_match "Discordスレッドに送りました", payload["assistant_reply"]
    assert_equal 1, discord_delivered.size
    assert_equal "ランチ入力をもっと楽にしたい", discord_delivered.first[:body]
    assert_equal "lunch", discord_delivered.first[:mode]
    assert_equal "READMEを先に読む", discord_delivered.first[:context]
  ensure
    DiscordAppMessageNotifier.define_singleton_method(:call, original_discord_call) if original_discord_call
  end

  test "signed in owner sees error when discord webhook is not configured" do
    sign_in_as_owner

    original_discord_call = DiscordAppMessageNotifier.method(:call)
    DiscordAppMessageNotifier.define_singleton_method(:call) do |body:, mode:, request:, context: nil|
      :skipped
    end

    post ai_messages_url(format: :json), params: { message: { body: "こんにちは", mode: "dashboard" } }

    assert_response :bad_gateway
    payload = JSON.parse(response.body)
    assert_equal false, payload["ok"]
    assert_match "Discord連携URLが未設定", payload["message"]
    assert_equal "failed", AiMessage.last.status
  ensure
    DiscordAppMessageNotifier.define_singleton_method(:call, original_discord_call) if original_discord_call
  end

  test "signed in owner forwards today's check out request to discord only without changing data" do
    sign_in_as_owner
    today = WorkDay.today
    today.update!(check_out_confirmed: false, check_out_confirmed_at: nil)

    discord_delivered = []
    original_discord_call = DiscordAppMessageNotifier.method(:call)
    DiscordAppMessageNotifier.define_singleton_method(:call) do |body:, mode:, request:, context: nil|
      discord_delivered << { body: body, mode: mode, request: request, context: context }
      :delivered
    end

    post ai_messages_url(format: :json), params: { message: { body: "今日の退勤して", mode: "dashboard" } }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert_equal "completed", payload["status"]
    assert_equal true, payload["completed"]
    assert_match "Discordスレッドに送りました", payload["assistant_reply"]
    assert_not WorkDay.today.check_out_confirmed?
    assert_nil WorkDay.today.check_out_confirmed_at
    assert_equal 1, discord_delivered.size
    assert_equal "今日の退勤して", discord_delivered.first[:body]
  ensure
    DiscordAppMessageNotifier.define_singleton_method(:call, original_discord_call) if original_discord_call
  end

  test "signed in owner forwards this month spending question to discord thread" do
    sign_in_as_owner

    discord_delivered = []
    original_discord_call = DiscordAppMessageNotifier.method(:call)
    DiscordAppMessageNotifier.define_singleton_method(:call) do |body:, mode:, request:, context: nil|
      discord_delivered << { body: body, mode: mode, request: request, context: context }
      :delivered
    end

    post ai_messages_url(format: :json), params: { message: { body: "今月いくら使った？？", mode: "budget" } }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert_equal "completed", payload["status"]
    assert_equal true, payload["completed"]
    assert_match "Discordスレッドに送りました", payload["assistant_reply"]
    assert_equal 1, discord_delivered.size
    assert_equal "今月いくら使った？？", discord_delivered.first[:body]
    assert_equal "budget", discord_delivered.first[:mode]
  ensure
    DiscordAppMessageNotifier.define_singleton_method(:call, original_discord_call) if original_discord_call
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
