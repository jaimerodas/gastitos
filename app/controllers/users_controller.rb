class UsersController < ApplicationController
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

  private

  def user_params
    params.expect(user: [ :name, :email, :password, :password_confirmation ])
  end
end
