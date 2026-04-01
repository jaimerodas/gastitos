class UsersController < ApplicationController
  before_action :require_login, only: [ :index, :show, :destroy, :activity_log ]
  before_action :require_admin, only: [ :index, :show, :destroy, :activity_log ]
  before_action :set_user, only: [ :show, :destroy, :activity_log ]

  def index
    @users = User.order(:name)
  end

  def show
    @activity_lines = ActivityLogger.recent_lines(@user)
  end

  def activity_log
    path = ActivityLogger.log_path(@user)

    if path.exist?
      send_file path, type: "text/plain", filename: "actividad_#{@user.name.parameterize}.log"
    else
      redirect_to user_path(@user), alert: t("users.admin.no_activity")
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      if @user.approved?
        session[:user_id] = @user.id
        redirect_to root_path
      else
        redirect_to new_session_path, notice: t("users.create.pending_approval")
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to user_path(@user), alert: t("users.admin.cannot_modify_self")
      return
    end

    if @user.destroy
      redirect_to users_path, notice: t("users.admin.destroyed")
    else
      redirect_to user_path(@user), alert: t("users.admin.destroy_failed")
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.expect(user: [ :name, :email, :password, :password_confirmation ])
  end
end
