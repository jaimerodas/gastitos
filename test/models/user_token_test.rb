require "test_helper"

class UserTokenTest < ActiveSupport::TestCase
  test "generates a password reset token" do
    token = users(:jaime).generate_token_for(:password_reset)
    assert_not_nil token
  end

  test "resolves a valid token back to the user" do
    user = users(:jaime)
    token = user.generate_token_for(:password_reset)
    assert_equal user, User.find_by_token_for(:password_reset, token)
  end

  test "token becomes invalid after password change" do
    user = users(:jaime)
    token = user.generate_token_for(:password_reset)
    user.update!(password: "newpassword456")
    assert_nil User.find_by_token_for(:password_reset, token)
  end

  test "invalid token returns nil" do
    assert_nil User.find_by_token_for(:password_reset, "bogus-token")
  end
end
