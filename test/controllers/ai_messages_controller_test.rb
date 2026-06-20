require "test_helper"

class AiMessagesControllerTest < ActionDispatch::IntegrationTest
  test "requires login" do
    post ai_messages_url, params: { message: { body: "UIをもう少し落ち着かせたい", mode: "dashboard" } }

    assert_redirected_to login_url
  end

  test "signed in owner can forward app message to discord" do
    sign_in_as_owner

    delivered = []
    original_call = DiscordAppMessageNotifier.method(:call)
    DiscordAppMessageNotifier.define_singleton_method(:call) do |body:, mode:, request:|
      delivered << { body: body, mode: mode, request: request }
    end

    post ai_messages_url(format: :json), params: { message: { body: "ランチ入力をもっと楽にしたい", mode: "lunch" } }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert_equal "Discordへ送信しました。必要ならこの内容をもとにアプリを調整します。", payload["message"]
    assert_equal 1, delivered.size
    assert_equal "ランチ入力をもっと楽にしたい", delivered.first[:body]
    assert_equal "lunch", delivered.first[:mode]
  ensure
    DiscordAppMessageNotifier.define_singleton_method(:call, original_call) if original_call
  end

  test "blank message is rejected" do
    sign_in_as_owner

    post ai_messages_url(format: :json), params: { message: { body: "   ", mode: "dashboard" } }

    assert_response :unprocessable_entity
    payload = JSON.parse(response.body)
    assert_equal false, payload["ok"]
  end
end
