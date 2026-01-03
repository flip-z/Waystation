class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_current_user
  before_action :authenticate_user!

  helper_method :current_user

  private

  def set_current_user
    Current.user = User.find_by(id: session[:user_id])
  end

  def current_user
    Current.user
  end

  def authenticate_user!
    return if Current.user

    redirect_to new_session_path, alert: "Please sign in to continue."
  end

  def require_admin!
    return if Current.user&.admin?

    redirect_to root_path, alert: "Not authorized."
  end
end
