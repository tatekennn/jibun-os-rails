class AiMessagesController < ApplicationController
  protect_from_forgery with: :exception

  def create
    body = message_params[:body].to_s.strip
    mode = message_params[:mode].presence || "dashboard"
    context = message_params[:context].to_s.strip.presence

    if body.blank?
      render json: { ok: false, message: "送信する文章を入力してください。" }, status: :unprocessable_entity
      return
    end

    ::DiscordAppMessageNotifier.call(body: body, mode: mode, request: request)
    hermes_result = ::HermesAppMessageNotifier.call(body: body, mode: mode, request: request, context: context)
    destination = hermes_result == :skipped ? "Discord" : "DiscordとHermes"

    render json: {
      ok: true,
      message: "#{destination}へ送信しました。必要ならこの内容をもとにアプリを調整します。"
    }
  rescue ::DiscordAppMessageNotifier::DeliveryError => error
    Rails.logger.warn("Discord app message delivery failed: #{error.message}")
    render json: { ok: false, message: "Discordへの送信に失敗しました。少し時間を置いて再送してください。" }, status: :bad_gateway
  rescue ::HermesAppMessageNotifier::DeliveryError => error
    Rails.logger.warn("Hermes app message delivery failed: #{error.message}")
    render json: { ok: false, message: "Hermesへの送信に失敗しました。少し時間を置いて再送してください。" }, status: :bad_gateway
  end

  private

  def message_params
    params.fetch(:message, {}).permit(:body, :mode, :context)
  end
end
