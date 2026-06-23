require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "protected pages redirect to login when signed out" do
    get root_url

    assert_redirected_to login_url
  end

  test "owner can sign in and see dashboard" do
    sign_in_as_owner

    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
    assert_select "strong", text: "自分OS"
  end

  test "owner login uses a persistent session cookie" do
    sign_in_as_owner

    set_cookie_header = response.headers["Set-Cookie"]
    assert_includes set_cookie_header, "_jibun_os_session="
    assert_match(/expires=/i, set_cookie_header)
  end

  test "wrong password keeps visitor on login" do
    post login_url, params: { session: { email: "owner@example.com", password: "wrong" } }

    assert_response :unprocessable_entity
    assert_select ".flash--alert", text: /ログインできませんでした/
  end

  test "owner can sign out" do
    sign_in_as_owner

    delete logout_url

    assert_redirected_to login_url
  end
end
