require "test_helper"

class ActivityEventsTest < ActiveSupport::TestCase
  # -- Simple events --

  test "Login message is the localized login string" do
    assert_equal I18n.t("activity.login"), ActivityEvents::Login.new.message
  end

  test "Logout message is the localized logout string" do
    assert_equal I18n.t("activity.logout"), ActivityEvents::Logout.new.message
  end

  test "PasswordResetRequested message is localized" do
    assert_equal I18n.t("activity.password_reset_requested"),
                 ActivityEvents::PasswordResetRequested.new.message
  end

  test "PasswordResetCompleted message is localized" do
    assert_equal I18n.t("activity.password_reset_completed"),
                 ActivityEvents::PasswordResetCompleted.new.message
  end

  # -- TransactionCreated --

  test "TransactionCreated formats expense with category and description" do
    txn = transactions(:lunch)
    msg = ActivityEvents::TransactionCreated.new(txn).message
    assert_includes msg, I18n.t("activity.types.expense")
    assert_includes msg, "$12.50"
    assert_includes msg, "Food: Tacos"
    assert_includes msg, "2026-03-28"
    assert_includes msg, "(ID: #{txn.id})"
  end

  test "TransactionCreated formats income" do
    txn = transactions(:paycheck)
    msg = ActivityEvents::TransactionCreated.new(txn).message
    assert_includes msg, I18n.t("activity.types.income")
    assert_includes msg, "$1000.00"
    assert_includes msg, "Salary: March salary"
  end

  test "TransactionCreated falls back to category name when description is blank" do
    txn = transactions(:uber)  # description is nil
    msg = ActivityEvents::TransactionCreated.new(txn).message
    assert_includes msg, "Rideshare"
    assert_not_includes msg, "Rideshare:"
  end

  # -- TransactionDestroyed --

  test "TransactionDestroyed formats expense with details" do
    txn = transactions(:lunch)
    msg = ActivityEvents::TransactionDestroyed.new(txn).message
    assert_includes msg, I18n.t("activity.types.expense")
    assert_includes msg, "$12.50"
    assert_includes msg, "Food: Tacos"
  end

  # -- TransactionUpdated --

  test "TransactionUpdated formats amount change" do
    txn = transactions(:lunch)
    txn.update!(amount: 20)
    msg = ActivityEvents::TransactionUpdated.new(txn).message
    assert_includes msg, "##{txn.id}"
    assert_includes msg, "$12.50"
    assert_includes msg, "$20.00"
  end

  test "TransactionUpdated formats description change with quotes" do
    txn = transactions(:lunch)
    txn.update!(description: "Burritos")
    msg = ActivityEvents::TransactionUpdated.new(txn).message
    assert_includes msg, '"Tacos"'
    assert_includes msg, '"Burritos"'
  end

  test "TransactionUpdated formats date change" do
    txn = transactions(:lunch)
    txn.update!(date: Date.new(2026, 3, 30))
    msg = ActivityEvents::TransactionUpdated.new(txn).message
    assert_includes msg, "2026-03-28"
    assert_includes msg, "2026-03-30"
  end

  test "TransactionUpdated formats category change" do
    txn = transactions(:lunch)
    txn.update!(category: categories(:rideshare))
    msg = ActivityEvents::TransactionUpdated.new(txn).message
    assert_includes msg, "Food"
    assert_includes msg, "Rideshare"
  end

  test "TransactionUpdated joins multiple changes with comma" do
    txn = transactions(:lunch)
    txn.update!(amount: 20, description: "Burritos")
    msg = ActivityEvents::TransactionUpdated.new(txn).message
    assert_match(/,/, msg.split(":", 2).last)
  end

  test "TransactionUpdated returns nil when no formattable change occurred" do
    txn = transactions(:lunch)
    txn.save!  # no changes
    assert_nil ActivityEvents::TransactionUpdated.new(txn).message
  end
end
