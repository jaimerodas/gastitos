require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "password_reset sends to user with correct subject" do
    user = users(:jaime)
    email = UserMailer.password_reset(user)

    assert_equal [ user.email ], email.to
    assert_match "contraseña", email.subject
  end

  test "password_reset includes reset link in body" do
    user = users(:jaime)
    email = UserMailer.password_reset(user)

    assert_match "password_resets", email.body.encoded
    assert_match user.name, email.body.encoded
  end
end
