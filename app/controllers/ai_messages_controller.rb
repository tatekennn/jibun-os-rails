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

    ai_message = AiMessage.create!(body: body, mode: mode, context: context)

    discord_result = ::DiscordAppMessageNotifier.call(body: body, mode: mode, request: request, context: context)

    if discord_result == :skipped
      ai_message.fail!(message: "Discord連携URLが未設定です。")
      render json: { ok: false, message: "Discord連携URLが未設定です。Render環境変数を確認してください。" }, status: :bad_gateway
      return
    else
      ai_message.complete!(reply: discord_handoff_reply)
      ai_message.update!(delivery_message: "Discordスレッドへ送信しました。")
    end

    render json: serialize_message(ai_message, initial: true)
  rescue ::DiscordAppMessageNotifier::DeliveryError => error
    Rails.logger.warn("Discord app message delivery failed: #{error.message}")
    ai_message&.fail!(message: "Discordへの送信に失敗しました。")
    render json: { ok: false, message: "Discordへの送信に失敗しました。少し時間を置いて再送してください。" }, status: :bad_gateway
  end

  def show
    ai_message = AiMessage.find_by!(public_id: params[:id])

    render json: serialize_message(ai_message)
  end

  private

  def message_params
    params.fetch(:message, {}).permit(:body, :mode, :context)
  end

  def serialize_message(ai_message, initial: false)
    {
      ok: true,
      id: ai_message.public_id,
      status: ai_message.status,
      message: ai_message.delivery_message.presence || "送信しました。",
      assistant_reply: ai_message.assistant_reply.presence || pending_reply_for(ai_message, initial: initial),
      completed: ai_message.finished?
    }
  end

  def pending_reply_for(ai_message, initial: false)
    return ai_message.error_message if ai_message.status == "failed"

    if initial
      "受け取りました。Discordスレッドへ送信しています。"
    else
      "まだ送信処理中です。もう少し待っています。"
    end
  end

  def discord_handoff_reply
    <<~REPLY.squish
      Discordスレッドに送りました。Hermesへの直接callbackは一旦使わず、以降はDiscord側で返事します。
      アプリ側では送信済みとして扱います。
    REPLY
  end
end
