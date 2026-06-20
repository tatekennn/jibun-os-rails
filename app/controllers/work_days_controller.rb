class WorkDaysController < ApplicationController
  def index
    @work_days = WorkDay.recent.limit(30)
  end

  def today
    @work_day = WorkDay.today
  end

  def update
    @work_day = WorkDay.find(params[:id])

    if @work_day.update(work_day_params)
      redirect_to today_work_days_path, notice: "今日のメモを保存しました。"
    else
      render :today, status: :unprocessable_entity
    end
  end

  def confirm_check_in
    WorkDay.today.confirm_check_in!
    redirect_back fallback_location: today_work_days_path, notice: "出勤打刻を確認済みにしました。"
  end

  def confirm_check_out
    WorkDay.today.confirm_check_out!
    redirect_back fallback_location: today_work_days_path, notice: "退勤打刻を確認済みにしました。"
  end

  private

  def work_day_params
    params.require(:work_day).permit(:memo)
  end
end
