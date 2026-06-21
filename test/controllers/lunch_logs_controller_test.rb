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

  test "should sort lunch logs by rating" do
    LunchLog.delete_all
    create_lunch_log!(shop_name: "Low Rating", rating: 2, visited_on: Date.new(2026, 6, 18))
    create_lunch_log!(shop_name: "High Rating", rating: 5, visited_on: Date.new(2026, 6, 17))
    create_lunch_log!(shop_name: "Middle Rating", rating: 4, visited_on: Date.new(2026, 6, 19))

    get lunch_logs_url(sort: "rating")

    assert_response :success
    assert_equal ["High Rating", "Middle Rating", "Low Rating"], lunch_log_names
  end

  test "should sort lunch logs by visit count" do
    LunchLog.delete_all
    create_lunch_log!(shop_name: "Solo Shop", rating: 5, visited_on: Date.new(2026, 6, 19))
    create_lunch_log!(shop_name: "Repeat Shop", rating: 3, visited_on: Date.new(2026, 6, 17))
    create_lunch_log!(shop_name: "Repeat Shop", rating: 4, visited_on: Date.new(2026, 6, 18))

    get lunch_logs_url(sort: "visits")

    assert_response :success
    assert_equal ["Repeat Shop", "Repeat Shop", "Solo Shop"], lunch_log_names
    assert_includes @response.body, "2回訪問"
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

  private

    def create_lunch_log!(attributes)
      LunchLog.create!({
        area: "渋谷",
        crowdedness: "普通",
        memo: "",
        price: 1000,
        repeat: false,
        solo_friendly: true
      }.merge(attributes))
    end

    def lunch_log_names
      css_select("article.compact-card .list-line strong").map { |element| element.text.strip }
    end
end
