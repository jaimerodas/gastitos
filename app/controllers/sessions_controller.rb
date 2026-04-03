class SessionsController < ApplicationController
  rate_limit to: 5, within: 20.seconds, only: :create

  def new
    redirect_to new_user_path unless User.exists?
  end

  def create
    user = User.authenticate_by(email: params[:email], password: params[:password])

    if user&.approved?
      session[:user_id] = user.id
      ActivityLogger.log_login(user)
      redirect_to root_path
    elsif user
      redirect_to new_session_path, alert: t("sessions.create.unapproved")
    else
      redirect_to new_session_path, alert: t("sessions.create.invalid")
    end
  end

  def destroy
    ActivityLogger.log_logout(current_user) if current_user
    session.delete(:user_id)
    redirect_to root_path
  end
end
