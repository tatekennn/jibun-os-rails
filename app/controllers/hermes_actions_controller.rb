class HermesActionsController < ApplicationController
  skip_before_action :require_login
  protect_from_forgery with: :null_session

  def create
    ai_message = AiMessage.find_by!(public_id: params[:id])

    unless valid_action_token?(ai_message)
      render json: { ok: false, message: "invalid token" }, status: :unauthorized
      return
    end

    case params[:action].to_s
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
    else
      render json: { ok: false, message: "unsupported action" }, status: :unprocessable_entity
    end
  end

  private

  def valid_action_token?(ai_message)
    token = params[:token].to_s
    return false if token.blank? || token.bytesize != ai_message.callback_token.bytesize

    ActiveSupport::SecurityUtils.secure_compare(ai_message.callback_token, token)
  end
end
