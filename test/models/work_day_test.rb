require "test_helper"

class WorkDayTest < ActiveSupport::TestCase
  test "application uses Tokyo time zone for work day timestamps" do
    assert_equal "Tokyo", Rails.application.config.time_zone
    assert_equal "Tokyo", Time.zone.name
  end

  test "confirm check in stores current time in Tokyo zone" do
    travel_to Time.zone.local(2026, 6, 20, 22, 21, 0) do
      work_day = WorkDay.find_or_create_by!(date: Date.current)

      work_day.confirm_check_in!

      assert_equal "2026-06-20 22:21", work_day.reload.check_in_confirmed_at.in_time_zone.strftime("%Y-%m-%d %H:%M")
    end
  end

  test "today follows Tokyo calendar date" do
    travel_to Time.utc(2026, 6, 20, 15, 30, 0) do
      assert_equal Date.new(2026, 6, 21), Date.current
      assert_equal Date.new(2026, 6, 21), WorkDay.today.date
    end
  end
end
