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
    assert_select "h1", text: "J.A.R.V.I.S.チャット"
    assert_select "[data-controller='ai-chat']"
    assert_select "textarea[aria-label='Hermesへの依頼入力']"
    assert_select "form[data-action='submit->ai-chat#send']"
  end
end
