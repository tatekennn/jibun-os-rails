class PwaController < ApplicationController
  skip_before_action :require_login

  def offline
  end
end
