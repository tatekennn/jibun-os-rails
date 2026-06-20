require "test_helper"

class LunchLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_owner
  end

  setup do
    @lunch_log = lunch_logs(:one)
  end

  test "should get index" do
    get lunch_logs_url
    assert_response :success
  end

  test "should get new" do
    get new_lunch_log_url
    assert_response :success
  end

  test "should create lunch_log" do
    assert_difference("LunchLog.count") do
      post lunch_logs_url, params: { lunch_log: { area: @lunch_log.area, crowdedness: @lunch_log.crowdedness, memo: @lunch_log.memo, price: @lunch_log.price, rating: @lunch_log.rating, repeat: @lunch_log.repeat, shop_name: @lunch_log.shop_name, solo_friendly: @lunch_log.solo_friendly, visited_on: @lunch_log.visited_on } }
    end

    assert_redirected_to lunch_logs_url
  end

  test "should show lunch_log" do
    get lunch_log_url(@lunch_log)
    assert_response :success
  end

  test "should get edit" do
    get edit_lunch_log_url(@lunch_log)
    assert_response :success
  end

  test "should update lunch_log" do
    patch lunch_log_url(@lunch_log), params: { lunch_log: { area: @lunch_log.area, crowdedness: @lunch_log.crowdedness, memo: @lunch_log.memo, price: @lunch_log.price, rating: @lunch_log.rating, repeat: @lunch_log.repeat, shop_name: @lunch_log.shop_name, solo_friendly: @lunch_log.solo_friendly, visited_on: @lunch_log.visited_on } }
    assert_redirected_to lunch_logs_url
  end

  test "should destroy lunch_log" do
    assert_difference("LunchLog.count", -1) do
      delete lunch_log_url(@lunch_log)
    end

    assert_redirected_to lunch_logs_url
  end
end
