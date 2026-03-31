class AdminRolesController < ApplicationController
  before_action :require_login
  before_action :require_admin
  before_action :set_user

  def create
    if @user == current_user
      redirect_to user_path(@user), alert: t("users.admin.cannot_modify_self")
      return
    end

    @user.update!(admin: true)
    redirect_to user_path(@user), notice: t("users.admin.admin_granted")
  end

  def destroy
    if @user == current_user
      redirect_to user_path(@user), alert: t("users.admin.cannot_modify_self")
      return
    end

    @user.update!(admin: false)
    redirect_to user_path(@user), notice: t("users.admin.admin_revoked")
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
