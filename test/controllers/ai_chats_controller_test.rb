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
end
