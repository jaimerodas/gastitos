require "test_helper"

class PasswordResetsTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "request reset page renders form" do
    get new_password_reset_path
    assert_response :success
    assert_select "h1", I18n.t("password_resets.new.title")
  end

  test "requesting reset with valid email sends email" do
    perform_enqueued_jobs do
      assert_emails 1 do
        post password_resets_path, params: { email: users(:jaime).email }
      end
    end
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "p[role=status]", /instrucciones/
  end

  test "requesting reset with unknown email still shows success" do
    perform_enqueued_jobs do
      assert_no_emails do
        post password_resets_path, params: { email: "nobody@example.com" }
      end
    end
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "p[role=status]", /instrucciones/
  end

  test "valid token shows password form" do
    token = users(:jaime).generate_token_for(:password_reset)
    get edit_password_reset_path(token: token)
    assert_response :success
    assert_select "h1", I18n.t("password_resets.edit.title")
  end

  test "invalid token redirects with error" do
    get edit_password_reset_path(token: "bad-token")
    assert_redirected_to new_password_reset_path
    follow_redirect!
    assert_select "p[role=alert]", /no es válido/
  end

  test "successful password update redirects to login" do
    user = users(:jaime)
    token = user.generate_token_for(:password_reset)

    patch password_reset_path(token: token), params: {
      user: { password: "newsecurepassword", password_confirmation: "newsecurepassword" }
    }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "p[role=status]", /actualizada/

    # Verify new password works
    post session_path, params: { email: user.email, password: "newsecurepassword" }
    assert_redirected_to root_path
  end

  test "password validation errors re-render form" do
    token = users(:jaime).generate_token_for(:password_reset)

    patch password_reset_path(token: token), params: {
      user: { password: "short", password_confirmation: "short" }
    }
    assert_response :unprocessable_entity
    assert_select "section[role=alert]"
  end

  test "update with invalid token redirects with error" do
    patch password_reset_path(token: "bad-token"), params: {
      user: { password: "newsecurepassword", password_confirmation: "newsecurepassword" }
    }
    assert_redirected_to new_password_reset_path
  end

  test "token is invalidated after successful password change" do
    user = users(:jaime)
    token = user.generate_token_for(:password_reset)

    patch password_reset_path(token: token), params: {
      user: { password: "newsecurepassword", password_confirmation: "newsecurepassword" }
    }
    assert_redirected_to new_session_path

    # Reusing the same token should fail
    get edit_password_reset_path(token: token)
    assert_redirected_to new_password_reset_path
  end
end
