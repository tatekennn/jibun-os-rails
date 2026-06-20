require "application_system_test_case"

class LunchLogsTest < ApplicationSystemTestCase
  setup do
    @lunch_log = lunch_logs(:one)
  end

  test "visiting the index" do
    visit lunch_logs_url
    assert_selector "h1", text: "Lunch logs"
  end

  test "should create lunch log" do
    visit lunch_logs_url
    click_on "New lunch log"

    fill_in "Area", with: @lunch_log.area
    fill_in "Crowdedness", with: @lunch_log.crowdedness
    fill_in "Memo", with: @lunch_log.memo
    fill_in "Price", with: @lunch_log.price
    fill_in "Rating", with: @lunch_log.rating
    check "Repeat" if @lunch_log.repeat
    fill_in "Shop name", with: @lunch_log.shop_name
    check "Solo friendly" if @lunch_log.solo_friendly
    fill_in "Visited on", with: @lunch_log.visited_on
    click_on "Create Lunch log"

    assert_text "Lunch log was successfully created"
    click_on "Back"
  end

  test "should update Lunch log" do
    visit lunch_log_url(@lunch_log)
    click_on "Edit this lunch log", match: :first

    fill_in "Area", with: @lunch_log.area
    fill_in "Crowdedness", with: @lunch_log.crowdedness
    fill_in "Memo", with: @lunch_log.memo
    fill_in "Price", with: @lunch_log.price
    fill_in "Rating", with: @lunch_log.rating
    check "Repeat" if @lunch_log.repeat
    fill_in "Shop name", with: @lunch_log.shop_name
    check "Solo friendly" if @lunch_log.solo_friendly
    fill_in "Visited on", with: @lunch_log.visited_on
    click_on "Update Lunch log"

    assert_text "Lunch log was successfully updated"
    click_on "Back"
  end

  test "should destroy Lunch log" do
    visit lunch_log_url(@lunch_log)
    click_on "Destroy this lunch log", match: :first

    assert_text "Lunch log was successfully destroyed"
  end
end
