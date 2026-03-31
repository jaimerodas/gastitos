class ApprovalsController < ApplicationController
  before_action :require_login
  before_action :require_admin
  before_action :set_user

  def create
    if @user == current_user
      redirect_to user_path(@user), alert: t("users.admin.cannot_modify_self")
      return
    end

    @user.update!(approved: true)
    redirect_to user_path(@user), notice: t("users.admin.approved")
  end

  def destroy
    if @user == current_user
      redirect_to user_path(@user), alert: t("users.admin.cannot_modify_self")
      return
    end

    @user.update!(approved: false)
    redirect_to user_path(@user), notice: t("users.admin.unapproved")
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
