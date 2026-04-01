require "test_helper"

class UsersAdminTest < ActionDispatch::IntegrationTest
  # === Authorization ===

  test "non-logged-in user is redirected to login for index" do
    get users_path
    assert_redirected_to new_session_path
  end

  test "non-logged-in user is redirected to login for show" do
    get user_path(users(:sofia))
    assert_redirected_to new_session_path
  end

  test "non-admin user is redirected to root for index" do
    log_in_as users(:sofia)
    get users_path
    assert_redirected_to root_path
  end

  test "non-admin user is redirected to root for show" do
    log_in_as users(:sofia)
    get user_path(users(:unapproved))
    assert_redirected_to root_path
  end

  test "non-admin user cannot approve" do
    log_in_as users(:sofia)
    post user_approval_path(users(:unapproved))
    assert_redirected_to root_path
    assert_not users(:unapproved).reload.approved?
  end

  test "non-admin user cannot change roles" do
    log_in_as users(:sofia)
    patch user_role_path(users(:unapproved)), params: { role: "editor" }
    assert_redirected_to root_path
    assert users(:unapproved).reload.viewer?
  end

  test "non-admin user cannot delete" do
    log_in_as users(:sofia)
    assert_no_difference "User.count" do
      delete user_path(users(:unapproved))
    end
    assert_redirected_to root_path
  end

  # === Index ===

  test "admin can see users index" do
    log_in_as users(:jaime)
    get users_path
    assert_response :success
    assert_select "h1", I18n.t("users.admin.index_title")
  end

  test "index shows all users with name, email, status, and permissions" do
    log_in_as users(:jaime)
    get users_path

    assert_select "ul#users li", count: User.count

    assert_select ".name", text: "Jaime"
    assert_select ".email", text: "jaime@example.com"
    assert_select ".status", text: I18n.t("users.admin.approved_status")
    assert_select ".role", text: I18n.t("users.admin.admin_role")

    assert_select ".name", text: "Pending"
    assert_select ".status", text: I18n.t("users.admin.pending_status")
    assert_select ".role", text: I18n.t("users.admin.viewer_role")
  end

  test "index names and emails link to show pages" do
    log_in_as users(:jaime)
    get users_path

    User.find_each do |user|
      assert_select "a[href=?]", user_path(user), minimum: 1
    end
  end

  # === Show ===

  test "admin can see user show page" do
    log_in_as users(:jaime)
    get user_path(users(:sofia))
    assert_response :success
    assert_select "h1", "Sofía"
  end

  test "show displays user details including creation date" do
    log_in_as users(:jaime)
    get user_path(users(:sofia))

    assert_select "main#user span", text: "sofia@example.com"
    assert_select "dd", text: I18n.t("users.admin.approved_status")
    assert_select "dd", text: I18n.t("users.admin.editor_role")
    assert_select "dt", text: I18n.t("users.admin.created_at")
  end

  test "show page for unapproved user has approve and delete buttons" do
    log_in_as users(:jaime)
    get user_path(users(:unapproved))

    assert_select "button", text: I18n.t("users.admin.approve_button")
    assert_select "button", text: I18n.t("users.admin.delete_button")
  end

  test "show page for approved user has unapprove button" do
    log_in_as users(:jaime)
    get user_path(users(:sofia))

    assert_select "button", text: I18n.t("users.admin.unapprove_button")
  end

  test "show page shows role change buttons for other roles" do
    log_in_as users(:jaime)
    get user_path(users(:sofia))

    # Sofia is editor, so should see buttons for viewer and admin
    assert_select "button", text: I18n.t("users.admin.make_role", role: I18n.t("users.admin.viewer_role").downcase)
    assert_select "button", text: I18n.t("users.admin.make_role", role: I18n.t("users.admin.admin_role").downcase)
  end

  test "show page for own user has no action buttons" do
    log_in_as users(:jaime)
    get user_path(users(:jaime))

    assert_select "section.actions", count: 0
  end

  # === Approve ===

  test "admin can approve a user" do
    log_in_as users(:jaime)
    post user_approval_path(users(:unapproved))

    assert users(:unapproved).reload.approved?
    assert_redirected_to user_path(users(:unapproved))
    follow_redirect!
    assert_select "p[role=status]", I18n.t("users.admin.approved")
  end

  # === Unapprove ===

  test "admin can revoke approval" do
    log_in_as users(:jaime)
    delete user_approval_path(users(:sofia))

    assert_not users(:sofia).reload.approved?
    assert_redirected_to user_path(users(:sofia))
    follow_redirect!
    assert_select "p[role=status]", I18n.t("users.admin.unapproved")
  end

  # === Role changes ===

  test "admin can change user role to admin" do
    log_in_as users(:jaime)
    patch user_role_path(users(:sofia)), params: { role: "admin" }

    assert users(:sofia).reload.admin?
    assert_redirected_to user_path(users(:sofia))
    follow_redirect!
    assert_select "p[role=status]", I18n.t("users.admin.role_updated")
  end

  test "admin can change user role to viewer" do
    log_in_as users(:jaime)
    patch user_role_path(users(:sofia)), params: { role: "viewer" }

    assert users(:sofia).reload.viewer?
    assert_redirected_to user_path(users(:sofia))
    follow_redirect!
    assert_select "p[role=status]", I18n.t("users.admin.role_updated")
  end

  test "admin cannot set invalid role" do
    log_in_as users(:jaime)
    patch user_role_path(users(:sofia)), params: { role: "superadmin" }

    assert users(:sofia).reload.editor?
    assert_redirected_to user_path(users(:sofia))
    follow_redirect!
    assert_select "p[role=alert]", I18n.t("users.admin.invalid_role")
  end

  # === Self-protection ===

  test "admin cannot approve self" do
    log_in_as users(:jaime)
    post user_approval_path(users(:jaime))

    assert_redirected_to user_path(users(:jaime))
    follow_redirect!
    assert_select "p[role=alert]", I18n.t("users.admin.cannot_modify_self")
  end

  test "admin cannot unapprove self" do
    log_in_as users(:jaime)
    delete user_approval_path(users(:jaime))

    assert users(:jaime).reload.approved?
    assert_redirected_to user_path(users(:jaime))
    follow_redirect!
    assert_select "p[role=alert]", I18n.t("users.admin.cannot_modify_self")
  end

  test "admin cannot change own role" do
    log_in_as users(:jaime)
    patch user_role_path(users(:jaime)), params: { role: "viewer" }

    assert users(:jaime).reload.admin?
    assert_redirected_to user_path(users(:jaime))
    follow_redirect!
    assert_select "p[role=alert]", I18n.t("users.admin.cannot_modify_self")
  end

  test "admin cannot delete self" do
    log_in_as users(:jaime)
    assert_no_difference "User.count" do
      delete user_path(users(:jaime))
    end
    assert_redirected_to user_path(users(:jaime))
    follow_redirect!
    assert_select "p[role=alert]", I18n.t("users.admin.cannot_modify_self")
  end

  # === Delete ===

  test "admin can delete user without transactions" do
    log_in_as users(:jaime)
    assert_difference "User.count", -1 do
      delete user_path(users(:unapproved))
    end
    assert_redirected_to users_path
    follow_redirect!
    assert_select "p[role=status]", I18n.t("users.admin.destroyed")
  end

  test "admin cannot delete user with transactions" do
    log_in_as users(:jaime)
    assert_no_difference "User.count" do
      delete user_path(users(:sofia))
    end
    assert_redirected_to user_path(users(:sofia))
    follow_redirect!
    assert_select "p[role=alert]", I18n.t("users.admin.destroy_failed")
  end

  # === Session invalidation ===

  test "revoking approval logs out the affected user on next request" do
    log_in_as users(:sofia)
    get root_path
    assert_response :success

    # Admin revokes Sofia's approval in a separate session
    reset!
    log_in_as users(:jaime)
    delete user_approval_path(users(:sofia))
    assert_not users(:sofia).reload.approved?

    # Sofia's next request should redirect to login
    reset!
    get root_path
    assert_redirected_to new_session_path
  end

  # === Nav link ===

  test "admin sees Usuarios link in nav when multiple users exist" do
    log_in_as users(:jaime)
    get root_path
    assert_select "nav a", text: I18n.t("layouts.application.users")
  end

  test "non-admin does not see Usuarios link in nav" do
    log_in_as users(:sofia)
    get root_path
    assert_select "nav a", text: I18n.t("layouts.application.users"), count: 0
  end
end
