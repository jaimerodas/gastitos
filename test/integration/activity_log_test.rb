require "test_helper"

class ActivityLogTest < ActionDispatch::IntegrationTest
  setup do
    @tmpdir = Dir.mktmpdir
    @original_default_dir = ActivityLogger::FileStore.default_dir
    ActivityLogger::FileStore.default_dir = Pathname.new(@tmpdir)
    @admin = users(:jaime)
    @editor = users(:sofia)
  end

  teardown do
    FileUtils.remove_entry(@tmpdir)
    ActivityLogger::FileStore.default_dir = @original_default_dir
  end

  # -- Transaction logging --

  test "creating a transaction logs activity for the acting user" do
    log_in_as @admin

    post transactions_path, params: { transaction: {
      "date(1i)" => "2026", "date(2i)" => "3", "date(3i)" => "30",
      amount: "15.50",
      category_id: categories(:food).id,
      description: "Tacos"
    } }

    lines = ActivityLogger.recent(@admin)
    assert_not_empty lines
    assert_includes lines.first, I18n.t("activity.types.expense")
    assert_includes lines.first, "Tacos"
  end

  test "updating a transaction logs changes for the acting user" do
    log_in_as @admin
    txn = transactions(:lunch)

    patch transaction_path(txn), params: { transaction: {
      "date(1i)" => "2026", "date(2i)" => "3", "date(3i)" => "28",
      amount: "20.00",
      category_id: categories(:food).id,
      description: "Burritos"
    } }

    lines = ActivityLogger.recent(@admin)
    assert_not_empty lines
    assert_includes lines.first, "##{txn.id}"
    assert_includes lines.first, I18n.t("activity.types.expense")
  end

  test "destroying a transaction logs activity for the acting user" do
    log_in_as @admin
    txn = transactions(:lunch)

    delete transaction_path(txn)

    lines = ActivityLogger.recent(@admin)
    assert_not_empty lines
    assert_includes lines.first, I18n.t("activity.types.expense")
    assert_includes lines.first, "Food"
  end

  # -- Session logging --

  test "logging in records activity" do
    log_in_as @editor

    lines = ActivityLogger.recent(@editor)
    assert_includes lines.join, I18n.t("activity.login")
  end

  test "logging out records activity" do
    log_in_as @editor
    delete session_path

    lines = ActivityLogger.recent(@editor)
    assert_includes lines.join, I18n.t("activity.logout")
  end

  # -- Password reset logging --

  test "requesting a password reset logs activity" do
    post password_resets_path, params: { email: @editor.email }

    lines = ActivityLogger.recent(@editor)
    assert_includes lines.join, I18n.t("activity.password_reset_requested")
  end

  test "completing a password reset logs activity" do
    token = @editor.generate_token_for(:password_reset)
    patch password_reset_path(token: token), params: {
      user: { password: "newpassword123", password_confirmation: "newpassword123" }
    }

    lines = ActivityLogger.recent(@editor)
    assert_includes lines.join, I18n.t("activity.password_reset_completed")
  end

  # -- Show page display --

  test "users show page displays recent activity lines" do
    ActivityLogger::FileStore.new.append(@editor, "Test activity line")
    log_in_as @admin

    get user_path(@editor)
    assert_response :success
    assert_select "section#activity pre", /Test activity line/
  end

  test "users show page shows no-activity message when log is empty" do
    log_in_as @admin
    get user_path(@editor)

    assert_response :success
    assert_select "section#activity p", I18n.t("users.admin.no_activity")
  end

  # -- Download --

  test "admin can download activity log" do
    ActivityLogger::FileStore.new.append(@editor, "Downloadable line")
    log_in_as @admin

    get activity_log_user_path(@editor)
    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_match(/Downloadable line/, response.body)
  end

  test "download redirects when no log file exists" do
    log_in_as @admin
    get activity_log_user_path(@editor)

    assert_redirected_to user_path(@editor)
  end

  test "non-admin cannot download activity log" do
    log_in_as @editor
    get activity_log_user_path(@admin)

    assert_redirected_to root_path
  end

  test "non-logged-in user cannot download activity log" do
    get activity_log_user_path(@editor)
    assert_redirected_to new_session_path
  end
end
