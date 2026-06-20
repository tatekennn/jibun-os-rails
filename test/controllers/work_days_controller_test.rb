require "test_helper"

class WorkDaysControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_owner
  end

  test "should get index" do
    get work_days_url
    assert_response :success
  end

  test "should get today" do
    get today_work_days_url
    assert_response :success
  end
end
