require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  # -- Root path redirects --

  test "root redirects to login when not logged in" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "root shows home page when logged in" do
    log_in_as users(:jaime)
    get root_path
    assert_response :success
    assert_select "h1", I18n.t("transactions.index.title")
  end

  # -- Login --

  test "login page shows login form" do
    get new_session_path
    assert_response :success
    assert_select "h1", "Iniciar sesión"
  end

  test "login with valid approved user" do
    post session_path, params: { email: users(:jaime).email, password: "password123" }
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "login with invalid credentials shows error" do
    post session_path, params: { email: users(:jaime).email, password: "wrong" }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "p[role=alert]", "Correo electrónico o contraseña incorrectos."
  end

  test "login with unapproved user shows approval message" do
    post session_path, params: { email: users(:unapproved).email, password: "password123" }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "p[role=alert]", "Tu cuenta aún no ha sido aprobada."
  end

  # -- Logout --

  test "logout clears session and redirects to root" do
    log_in_as users(:jaime)
    delete session_path
    assert_redirected_to root_path
    follow_redirect!
    assert_redirected_to new_session_path
  end

  # -- Signup --

  test "signup page shows registration form" do
    get new_user_path
    assert_response :success
    assert_select "h1", "Crear cuenta"
  end

  test "signup with valid data when users exist creates unapproved user" do
    assert_difference "User.count", 1 do
      post users_path, params: { user: {
        name: "New User", email: "new@example.com",
        password: "password123", password_confirmation: "password123"
      } }
    end
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "p[role=status]", /administrador debe aprobar/

    user = User.find_by(email: "new@example.com")
    assert_not user.admin?
    assert_not user.approved?
  end

  test "signup with invalid data re-renders form with errors" do
    assert_no_difference "User.count" do
      post users_path, params: { user: {
        name: "", email: "bad", password: "short", password_confirmation: "nope"
      } }
    end
    assert_response :unprocessable_entity
    assert_select "section[role=alert]"
  end

  # -- First user --

  test "login page redirects to signup when no users exist" do
    Transaction.delete_all
    User.delete_all
    get new_session_path
    assert_redirected_to new_user_path
  end

  test "signup page hides login link when no users exist" do
    Transaction.delete_all
    User.delete_all
    get new_user_path
    assert_select "a[href='#{new_session_path}']", count: 0
  end

  test "signup page shows login link when users exist" do
    get new_user_path
    assert_select "a[href='#{new_session_path}']", "¿Ya tienes cuenta? Inicia sesión"
  end

  test "first user is auto-approved and logged in" do
    Transaction.delete_all
    User.delete_all
    post users_path, params: { user: {
      name: "First", email: "first@example.com",
      password: "password123", password_confirmation: "password123"
    } }
    assert_redirected_to root_path

    user = User.find_by(email: "first@example.com")
    assert user.admin?
    assert user.approved?
  end
end
