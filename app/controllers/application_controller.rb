class ApplicationController < ActionController::Base
  before_action :http_basic_authenticate

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def http_basic_authenticate
    if valid_user && valid_pswd
      authenticate_or_request_with_http_basic do |username, password|
        username == valid_user && password == valid_pswd
      end
    end
  end

  def valid_user
    ENV["BASIC_AUTH_USER"].presence
  end

  def valid_pswd
    ENV["BASIC_AUTH_PASSWORD"].presence
  end
end
