require "test_helper"

class RateLimitingTest < ActionDispatch::IntegrationTest
  test "throttles login after too many attempts" do
    6.times do
      post session_path, params: { email: "test@example.com", password: "wrong" }
    end

    assert_response :too_many_requests
  end

  test "throttles password reset requests after too many attempts" do
    6.times do
      post password_resets_path, params: { email: "test@example.com" }
    end

    assert_response :too_many_requests
  end

  test "throttles password reset updates after too many attempts" do
    6.times do
      patch password_reset_path(token: "invalid"), params: {
        user: { password: "newpassword", password_confirmation: "newpassword" }
      }
    end

    assert_response :too_many_requests
  end
end
