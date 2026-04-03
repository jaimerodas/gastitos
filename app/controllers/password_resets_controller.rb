class PasswordResetsController < ApplicationController
  rate_limit to: 5, within: 1.minute, only: [ :create, :update ]

  def new
  end

  def create
    if (user = User.find_by(email: params[:email]))
      ActivityLogger.log_password_reset_requested(user)
      UserMailer.password_reset(user).deliver_later
    end

    redirect_to new_session_path, notice: t("password_resets.create.success")
  end

  def edit
    @user = User.find_by_token_for(:password_reset, params[:token])

    unless @user
      redirect_to new_password_reset_path, alert: t("password_resets.invalid_token")
    end
  end

  def update
    @user = User.find_by_token_for(:password_reset, params[:token])

    unless @user
      redirect_to new_password_reset_path, alert: t("password_resets.invalid_token")
      return
    end

    if @user.update(password_params)
      ActivityLogger.log_password_reset_completed(@user)
      redirect_to new_session_path, notice: t("password_resets.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
