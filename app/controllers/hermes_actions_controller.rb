class HermesActionsController < ApplicationController
  skip_before_action :require_login
  protect_from_forgery with: :null_session

  def create
    ai_message = AiMessage.find_by!(public_id: params[:id])

    unless valid_action_token?(ai_message)
      render json: { ok: false, message: "invalid token" }, status: :unauthorized
      return
    end

    case requested_operation
    when "confirm_check_in"
      work_day = WorkDay.today
      already_confirmed = work_day.check_in_confirmed?
      work_day.confirm_check_in!
      render json: {
        ok: true,
        action: "confirm_check_in",
        already_confirmed: already_confirmed,
        message: already_confirmed ? "今日の出勤打刻はすでに確認済みでした。確認時刻を更新しました。" : "今日の出勤打刻を確認済みにしました。"
      }
    when "confirm_check_out"
      work_day = WorkDay.today
      already_confirmed = work_day.check_out_confirmed?
      work_day.confirm_check_out!
      render json: {
        ok: true,
        action: "confirm_check_out",
        already_confirmed: already_confirmed,
        message: already_confirmed ? "今日の退勤打刻はすでに確認済みでした。確認時刻を更新しました。" : "今日の退勤打刻を確認済みにしました。お疲れさまでした。"
      }
    when "monthly_spending_summary"
      render json: monthly_spending_summary
    else
      render json: { ok: false, message: "unsupported operation" }, status: :unprocessable_entity
    end
  end

  private

  def requested_operation
    params[:operation].to_s
  end

  def valid_action_token?(ai_message)
    token = params[:token].to_s
    return false if token.blank? || token.bytesize != ai_message.callback_token.bytesize

    ActiveSupport::SecurityUtils.secure_compare(ai_message.callback_token, token)
  end

  def monthly_spending_summary
    paid_rides = PaidRide.this_month
    lunch_logs = LunchLog.this_month
    paid_total = paid_rides.sum(:fare).to_i
    lunch_total = lunch_logs.sum(:price).to_i
    total = paid_total + lunch_total

    {
      ok: true,
      action: "monthly_spending_summary",
      month: Date.current.strftime("%Y-%m"),
      total: total,
      paid_rides: {
        count: paid_rides.count,
        total: paid_total
      },
      lunch_logs: {
        count: lunch_logs.count,
        total: lunch_total
      },
      message: "今月の記録済み支出は合計#{yen(total)}です。内訳は、有料列車#{paid_rides.count}回で#{yen(paid_total)}、ランチ#{lunch_logs.count}件で#{yen(lunch_total)}です。"
    }
  end

  def yen(amount)
    "¥#{amount.to_i.to_fs(:delimited)}"
  end
end
