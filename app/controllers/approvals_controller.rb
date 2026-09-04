class ApprovalsController < ApplicationController
  before_action :require_login
  before_action :require_admin
  before_action :set_user
  before_action :forbid_self

  def create
    @user.update!(approved: true)
    redirect_to user_path(@user), notice: t("users.admin.approved")
  end

  def destroy
    @user.update!(approved: false)
    redirect_to user_path(@user), notice: t("users.admin.unapproved")
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
