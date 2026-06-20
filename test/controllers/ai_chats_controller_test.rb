require "test_helper"

class AiChatsControllerTest < ActionDispatch::IntegrationTest
  test "requires login" do
    get ai_chat_url

    assert_redirected_to login_url
  end

  test "signed in owner can open dedicated chat page" do
    sign_in_as_owner

    get ai_chat_url

    assert_response :success
    assert_select "h1", text: "AIチャット"
    assert_select "[data-controller='ai-chat']"
    assert_select "[data-ai-chat-endpoint-value='#{ai_messages_path(format: :json)}']"
    assert_select "textarea[aria-label='AIチャット入力']"
    assert_select "form[data-action='submit->ai-chat#send']"
    assert_select "p", text: /Hermes Agentが処理/
  end

  test "signed in owner sees the latest five completed conversation rallies" do
    sign_in_as_owner

    6.times do |index|
      message = AiMessage.create!(body: "過去の依頼#{index + 1}", mode: "dashboard", created_at: index.minutes.ago, updated_at: index.minutes.ago)
      message.complete!(reply: "過去の返信#{index + 1}")
    end

    get ai_chat_url

    assert_response :success
    assert_select ".chat-room__history-label", text: "直近5ラリー"
    assert_select ".ai-dock__message--you", count: 5
    assert_select ".ai-dock__message--ai", count: 5
    assert_select "p", text: /過去の依頼1/
    assert_select "p", text: /過去の返信1/
    assert_select "p", text: /過去の依頼5/
    assert_select "p", text: /過去の返信5/
    assert_select "p", { text: /過去の依頼6/, count: 0 }
    assert_select "p", { text: /過去の返信6/, count: 0 }
  end
end
