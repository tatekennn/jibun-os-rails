class AiMessagesController < ApplicationController
  protect_from_forgery with: :exception

  def create
    body = message_params[:body].to_s.strip
    mode = message_params[:mode].presence || "dashboard"

    if body.blank?
      render json: { ok: false, message: "送信する文章を入力してください。" }, status: :unprocessable_entity
      return
    end

    ::DiscordAppMessageNotifier.call(body: body, mode: mode, request: request)

    render json: {
      ok: true,
      message: "Discordへ送信しました。必要ならこの内容をもとにアプリを調整します。"
    }
  rescue ::DiscordAppMessageNotifier::DeliveryError => error
    Rails.logger.warn("Discord app message delivery failed: #{error.message}")
    render json: { ok: false, message: "Discordへの送信に失敗しました。少し時間を置いて再送してください。" }, status: :bad_gateway
  end

  private

  def message_params
    params.fetch(:message, {}).permit(:body, :mode)
  end
end
