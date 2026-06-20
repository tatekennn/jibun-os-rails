require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_owner
  end

  test "should get index" do
    get root_url
    assert_response :success
  end
end
