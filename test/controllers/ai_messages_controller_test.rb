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
    HermesAppMessageNotifier.define_singleton_method(:call) do |body:, mode:, request:|
      hermes_delivered << { body: body, mode: mode, request: request }
    end

    post ai_messages_url(format: :json), params: { message: { body: "ランチ入力をもっと楽にしたい", mode: "lunch" } }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert_equal "DiscordとHermesへ送信しました。必要ならこの内容をもとにアプリを調整します。", payload["message"]
    assert_equal 1, discord_delivered.size
    assert_equal "ランチ入力をもっと楽にしたい", discord_delivered.first[:body]
    assert_equal "lunch", discord_delivered.first[:mode]
    assert_equal 1, hermes_delivered.size
    assert_equal "ランチ入力をもっと楽にしたい", hermes_delivered.first[:body]
    assert_equal "lunch", hermes_delivered.first[:mode]
  ensure
    DiscordAppMessageNotifier.define_singleton_method(:call, original_discord_call) if original_discord_call
    HermesAppMessageNotifier.define_singleton_method(:call, original_hermes_call) if original_hermes_call
  end

  test "blank message is rejected" do
    sign_in_as_owner

    post ai_messages_url(format: :json), params: { message: { body: "   ", mode: "dashboard" } }

    assert_response :unprocessable_entity
    payload = JSON.parse(response.body)
    assert_equal false, payload["ok"]
  end
end
