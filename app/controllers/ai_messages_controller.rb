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
      message: "#{destination}へ送信しました。",
      assistant_reply: assistant_reply_for(body: body, mode: mode, hermes_result: hermes_result)
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

  def assistant_reply_for(body:, mode:, hermes_result:)
    prefix = case mode
    when "rest"
      "疲れ気味として受け取りました。"
    when "budget"
      "節約まわりの相談として受け取りました。"
    when "lunch"
      "ランチまわりの相談として受け取りました。"
    when "hobby"
      "趣味まわりの相談として受け取りました。"
    else
      "内容を受け取りました。"
    end

    if hermes_result == :skipped
      "#{prefix} いまはアプリ内の返信だけ表示しています。外部連携を有効にすると、この内容を作業依頼として送れます。"
    else
      "#{prefix} 依頼は送信済みです。必要な確認や作業がある場合は、この内容をもとに進めます。"
    end
  end
end
