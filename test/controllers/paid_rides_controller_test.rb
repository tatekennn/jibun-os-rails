require "test_helper"

class PaidRidesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_owner
  end

  setup do
    @paid_ride = paid_rides(:one)
  end

  test "should get index" do
    get paid_rides_url
    assert_response :success
  end

  test "should get new" do
    get new_paid_ride_url
    assert_response :success
  end

  test "should create paid_ride" do
    assert_difference("PaidRide.count") do
      post paid_rides_url, params: { paid_ride: { direction: @paid_ride.direction, fare: @paid_ride.fare, fatigue_level: @paid_ride.fatigue_level, line_name: @paid_ride.line_name, memo: @paid_ride.memo, reason: @paid_ride.reason, used_on: @paid_ride.used_on } }
    end

    assert_redirected_to paid_rides_url
  end

  test "should show paid_ride" do
    get paid_ride_url(@paid_ride)
    assert_response :success
  end

  test "should get edit" do
    get edit_paid_ride_url(@paid_ride)
    assert_response :success
  end

  test "should update paid_ride" do
    patch paid_ride_url(@paid_ride), params: { paid_ride: { direction: @paid_ride.direction, fare: @paid_ride.fare, fatigue_level: @paid_ride.fatigue_level, line_name: @paid_ride.line_name, memo: @paid_ride.memo, reason: @paid_ride.reason, used_on: @paid_ride.used_on } }
    assert_redirected_to paid_rides_url
  end

  test "should destroy paid_ride" do
    assert_difference("PaidRide.count", -1) do
      delete paid_ride_url(@paid_ride)
    end

    assert_redirected_to paid_rides_url
  end
end
