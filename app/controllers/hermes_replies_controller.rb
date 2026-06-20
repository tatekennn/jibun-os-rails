class HermesRepliesController < ApplicationController
  skip_before_action :require_login
  protect_from_forgery with: :null_session

  def create
    ai_message = AiMessage.find_by!(public_id: params[:id])

    unless valid_callback_token?(ai_message)
      render json: { ok: false, message: "invalid token" }, status: :unauthorized
      return
    end

    if params[:error].present?
      ai_message.fail!(message: params[:error])
      PushNotificationDelivery.ai_reply_finished!(ai_message)
      render json: { ok: true, status: ai_message.status }
      return
    end

    reply = params[:reply].presence || params[:assistant_reply].presence || params[:message].presence

    if reply.blank?
      render json: { ok: false, message: "reply is required" }, status: :unprocessable_entity
      return
    end

    ai_message.complete!(reply: reply)
    PushNotificationDelivery.ai_reply_finished!(ai_message)
    render json: { ok: true, status: ai_message.status }
  end

  private

  def valid_callback_token?(ai_message)
    token = params[:token].to_s
    return false if token.blank? || token.bytesize != ai_message.callback_token.bytesize

    ActiveSupport::SecurityUtils.secure_compare(ai_message.callback_token, token)
  end
end
