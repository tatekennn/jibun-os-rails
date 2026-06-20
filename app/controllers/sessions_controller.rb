class SessionsController < ApplicationController
  skip_before_action :require_login

  def new
    redirect_to root_path if logged_in?
  end

  def create
    if owner_credentials_valid?
      session[:owner_authenticated] = true
      redirect_to root_path, notice: "おかえりなさい。自分OSを起動しました。"
    else
      flash.now[:alert] = "ログインできませんでした。メールアドレスとパスワードを確認してください。"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "ログアウトしました。"
  end

  private

  def owner_credentials_valid?
    submitted_email = session_params[:email].to_s.strip
    submitted_password = session_params[:password].to_s

    secure_compare(submitted_email, owner_email) && secure_compare(submitted_password, owner_password)
  end

  def session_params
    params.fetch(:session, {}).permit(:email, :password)
  end

  def owner_email
    ENV.fetch("JIBUN_OS_LOGIN_EMAIL", Rails.env.production? ? "" : "owner@example.com")
  end

  def owner_password
    ENV.fetch("JIBUN_OS_LOGIN_PASSWORD", Rails.env.production? ? "" : "password")
  end

  def secure_compare(left, right)
    return false if left.blank? || right.blank?

    ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(left),
      Digest::SHA256.hexdigest(right)
    )
  end
end
