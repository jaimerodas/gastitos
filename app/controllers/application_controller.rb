class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def current_user
    if session[:user_id]
      @current_user ||= User.find_by(id: session[:user_id])
      if @current_user && !@current_user.approved?
        session.delete(:user_id)
        @current_user = nil
      end
      @current_user
    end
  end
  helper_method :current_user

  def require_login
    redirect_to new_session_path unless current_user
  end

  def require_admin
    redirect_to root_path unless current_user&.admin?
  end

  def require_editor
    redirect_to root_path unless current_user&.can_edit?
  end
end
