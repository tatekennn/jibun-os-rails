require "test_helper"

class PwaControllerTest < ActionDispatch::IntegrationTest
  test "should get offline" do
    get offline_url
    assert_response :success
  end
end
