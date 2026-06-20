class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :require_login
  helper_method :logged_in?

  private

  def logged_in?
    session[:owner_authenticated] == true
  end

  def require_login
    return if logged_in?

    redirect_to login_path, alert: "自分OSを開くにはログインしてください。"
  end
end
