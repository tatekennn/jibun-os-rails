class PushSubscriptionsController < ApplicationController
  protect_from_forgery with: :exception

  def create
    unless push_notifications_configured?
      render json: { ok: false, message: "server push is not configured" }, status: :service_unavailable
      return
    end

    subscription = PushSubscription.upsert_from_params!(subscription_params.to_h, user_agent: request.user_agent)
    render json: { ok: true, id: subscription.id }
  rescue KeyError, ActionController::ParameterMissing
    render json: { ok: false, message: "subscription is invalid" }, status: :unprocessable_entity
  end

  def destroy
    PushSubscription.find_by(endpoint: params[:endpoint].to_s)&.destroy
    render json: { ok: true }
  end

  private

  def subscription_params
    params.require(:subscription).permit(:endpoint, keys: %i[p256dh auth])
  end

  def push_notifications_configured?
    ENV["VAPID_PUBLIC_KEY"].present? && ENV["VAPID_PRIVATE_KEY"].present?
  end
end
