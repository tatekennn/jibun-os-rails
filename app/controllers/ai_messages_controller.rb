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

    local_reply = handle_local_command(body)
    if local_reply.present?
      ai_message.complete!(reply: local_reply)
      ai_message.update!(delivery_message: "アプリ内で処理しました。")
      render json: serialize_message(ai_message, initial: true)
      return
    end

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

  def handle_local_command(body)
    normalized_body = body.to_s.tr("　", " ").strip

    return monthly_spending_reply if monthly_spending_query?(normalized_body)

    if normalized_body.match?(/退勤/) && normalized_body.match?(/今日|きょう|して|打刻|確認/)
      work_day = WorkDay.today
      already_confirmed = work_day.check_out_confirmed?
      work_day.confirm_check_out!

      if already_confirmed
        "今日の退勤打刻はすでに確認済みでした。念のため、確認時刻を更新しました。"
      else
        "今日の退勤打刻を確認済みにしました。お疲れさまでした。"
      end
    end
  end

  def monthly_spending_query?(body)
    body.match?(/今月|月/) && body.match?(/いくら|幾ら|使|支出|出費|金額|合計|お金/)
  end

  def monthly_spending_reply
    paid_rides = PaidRide.this_month
    lunch_logs = LunchLog.this_month
    paid_total = paid_rides.sum(:fare).to_i
    lunch_total = lunch_logs.sum(:price).to_i
    total = paid_total + lunch_total

    <<~REPLY.squish
      今月の記録済み支出は合計#{yen(total)}です。
      内訳は、有料列車#{paid_rides.count}回で#{yen(paid_total)}、ランチ#{lunch_logs.count}件で#{yen(lunch_total)}。
      ※自分OSに記録されている「有料列車」と「ランチ」の合計です。
    REPLY
  end

  def yen(amount)
    "¥#{amount.to_i.to_fs(:delimited)}"
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
