class DashboardController < ApplicationController
  def show
    redirect_to root_path
  end

  def index
    @today = Date.current
    @work_day = WorkDay.today
    @month_paid_rides = PaidRide.this_month.recent
    @recent_lunch_logs = LunchLog.recent.limit(3)
    @next_hobby_item = HobbyItem.events.planned.where("scheduled_on >= ?", @today).order(:scheduled_on).first
    @recent_hobby_memo = HobbyItem.memos.recent.first
    @reminder = current_reminder(@work_day)
  end

  private

  def current_reminder(work_day)
    now = Time.current

    if now.hour == 9 || (now.hour == 10 && now.min <= 10)
      return "出勤打刻した？" unless work_day.check_in_confirmed?
    end

    if (now.hour == 18 && now.min >= 30) || now.hour == 19
      return "退勤打刻した？" unless work_day.check_out_confirmed?
    end

    nil
  end
end
