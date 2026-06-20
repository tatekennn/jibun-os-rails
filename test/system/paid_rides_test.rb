require "application_system_test_case"

class PaidRidesTest < ApplicationSystemTestCase
  setup do
    @paid_ride = paid_rides(:one)
  end

  test "visiting the index" do
    visit paid_rides_url
    assert_selector "h1", text: "Paid rides"
  end

  test "should create paid ride" do
    visit paid_rides_url
    click_on "New paid ride"

    fill_in "Direction", with: @paid_ride.direction
    fill_in "Fare", with: @paid_ride.fare
    fill_in "Fatigue level", with: @paid_ride.fatigue_level
    fill_in "Line name", with: @paid_ride.line_name
    fill_in "Memo", with: @paid_ride.memo
    fill_in "Reason", with: @paid_ride.reason
    fill_in "Used on", with: @paid_ride.used_on
    click_on "Create Paid ride"

    assert_text "Paid ride was successfully created"
    click_on "Back"
  end

  test "should update Paid ride" do
    visit paid_ride_url(@paid_ride)
    click_on "Edit this paid ride", match: :first

    fill_in "Direction", with: @paid_ride.direction
    fill_in "Fare", with: @paid_ride.fare
    fill_in "Fatigue level", with: @paid_ride.fatigue_level
    fill_in "Line name", with: @paid_ride.line_name
    fill_in "Memo", with: @paid_ride.memo
    fill_in "Reason", with: @paid_ride.reason
    fill_in "Used on", with: @paid_ride.used_on
    click_on "Update Paid ride"

    assert_text "Paid ride was successfully updated"
    click_on "Back"
  end

  test "should destroy Paid ride" do
    visit paid_ride_url(@paid_ride)
    click_on "Destroy this paid ride", match: :first

    assert_text "Paid ride was successfully destroyed"
  end
end
