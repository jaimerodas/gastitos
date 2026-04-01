class UserMailer < ApplicationMailer
  def password_reset(user)
    @user = user
    @token = user.generate_token_for(:password_reset)
    mail to: @user.email, subject: t("user_mailer.password_reset.subject")
  end
end
