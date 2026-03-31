require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  test "valid expense transaction" do
    txn = build_transaction(category: categories(:food), amount: 25)
    assert txn.valid?
  end

  test "valid income transaction" do
    txn = build_transaction(category: categories(:salary), amount: 500)
    assert txn.valid?
  end

  test "requires an amount" do
    txn = build_transaction(amount: nil)
    assert_not txn.valid?
    assert txn.errors[:amount].any?
  end

  test "amount cannot be zero" do
    txn = build_transaction(amount: 0)
    assert_not txn.valid?
    assert txn.errors[:amount].any?
  end

  test "requires a date" do
    txn = build_transaction(date: nil)
    assert_not txn.valid?
    assert txn.errors[:date].any?
  end

  test "requires a category" do
    txn = build_transaction(category: nil)
    assert_not txn.valid?
  end

  test "description is optional" do
    txn = build_transaction(description: nil)
    assert txn.valid?
  end

  test "description max length is 140" do
    txn = build_transaction(description: "a" * 141)
    assert_not txn.valid?
    assert txn.errors[:description].any?
  end

  test "expense category makes amount negative" do
    txn = build_transaction(category: categories(:food), amount: 25)
    txn.valid?
    assert_equal(-25.0, txn.amount)
  end

  test "expense category keeps already-negative amount negative" do
    txn = build_transaction(category: categories(:food), amount: -25)
    txn.valid?
    assert_equal(-25.0, txn.amount)
  end

  test "income category makes amount positive" do
    txn = build_transaction(category: categories(:salary), amount: 500)
    txn.valid?
    assert_equal(500.0, txn.amount)
  end

  test "income category flips negative amount to positive" do
    txn = build_transaction(category: categories(:salary), amount: -500)
    txn.valid?
    assert_equal(500.0, txn.amount)
  end

  test "recent scope orders by date desc then created_at desc" do
    txns = Transaction.recent
    assert_equal transactions(:uber), txns.first
    assert_equal transactions(:paycheck), txns.last
  end

  # -- Monthly period callbacks --

  test "creating a transaction ensures monthly period exists" do
    assert_difference "MonthlyPeriod.count", 1 do
      build_transaction(date: Date.new(2025, 6, 15)).save!
    end
    assert MonthlyPeriod.find_by(month: 6, year: 2025)
  end

  test "creating a transaction in existing period does not duplicate" do
    assert_no_difference "MonthlyPeriod.count" do
      build_transaction(date: Date.new(2026, 3, 15)).save!
    end
  end

  test "changing transaction date to new month creates new period" do
    txn = transactions(:lunch)
    txn.update!(date: Date.new(2026, 4, 1))
    assert MonthlyPeriod.find_by(month: 4, year: 2026)
  end

  test "changing transaction date cleans up empty old period" do
    # Create a lone transaction in February
    txn = build_transaction(date: Date.new(2026, 2, 10))
    txn.save!
    assert MonthlyPeriod.find_by(month: 2, year: 2026)

    # Move it to March (which already has transactions)
    txn.update!(date: Date.new(2026, 3, 10))
    assert_nil MonthlyPeriod.find_by(month: 2, year: 2026)
  end

  test "changing transaction date keeps old period if not empty" do
    txn = transactions(:lunch)
    txn.update!(date: Date.new(2026, 4, 1))
    # March still has uber and paycheck
    assert MonthlyPeriod.find_by(month: 3, year: 2026)
  end

  test "destroying last transaction in a month deletes the period" do
    txn = build_transaction(date: Date.new(2026, 2, 10))
    txn.save!
    assert MonthlyPeriod.find_by(month: 2, year: 2026)

    txn.destroy
    assert_nil MonthlyPeriod.find_by(month: 2, year: 2026)
  end

  test "destroying a transaction keeps period if others remain" do
    transactions(:lunch).destroy
    assert MonthlyPeriod.find_by(month: 3, year: 2026)
  end

  private

  def build_transaction(overrides = {})
    defaults = {
      amount: 10,
      date: Date.current,
      category: categories(:food),
      created_by: users(:jaime)
    }
    Transaction.new(defaults.merge(overrides))
  end
end
