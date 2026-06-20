require "test_helper"

class HomeMocksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_owner
  end

  test "should get index" do
    get home_mocks_url
    assert_response :success
    assert_select "h1", "ホーム案"
    assert_select ".mock-variant", 12
  end
end
