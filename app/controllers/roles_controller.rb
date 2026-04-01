class RolesController < ApplicationController
  before_action :require_login
  before_action :require_admin
  before_action :set_user

  def update
    if @user == current_user
      redirect_to user_path(@user), alert: t("users.admin.cannot_modify_self")
      return
    end

    role = params[:role]
    unless User.roles.key?(role)
      redirect_to user_path(@user), alert: t("users.admin.invalid_role")
      return
    end

    @user.update!(role: role)
    redirect_to user_path(@user), notice: t("users.admin.role_updated")
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
