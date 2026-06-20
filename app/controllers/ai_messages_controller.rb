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

    ::DiscordAppMessageNotifier.call(body: body, mode: mode, request: request)
    hermes_result = ::HermesAppMessageNotifier.call(
      body: body,
      mode: mode,
      request: request,
      context: context,
      ai_message: ai_message
    )

    if hermes_result == :skipped
      ai_message.complete!(reply: "Hermes連携URLが未設定のため、アプリ内返信はここで止めています。")
      ai_message.update!(delivery_message: "Discordへ送信しました。")
    else
      ai_message.mark_delivered!(message: "DiscordとHermesへ送信しました。")
    end

    render json: serialize_message(ai_message, initial: true)
  rescue ::DiscordAppMessageNotifier::DeliveryError => error
    Rails.logger.warn("Discord app message delivery failed: #{error.message}")
    ai_message&.fail!(message: "Discordへの送信に失敗しました。")
    render json: { ok: false, message: "Discordへの送信に失敗しました。少し時間を置いて再送してください。" }, status: :bad_gateway
  rescue ::HermesAppMessageNotifier::DeliveryError => error
    Rails.logger.warn("Hermes app message delivery failed: #{error.message}")
    ai_message&.fail!(message: "Hermesへの送信に失敗しました。")
    render json: { ok: false, message: "Hermesへの送信に失敗しました。少し時間を置いて再送してください。" }, status: :bad_gateway
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
      "受け取りました。実行結果が戻るまで、この画面で待機します。"
    else
      "まだ処理中です。もう少し待っています。"
    end
  end
end
