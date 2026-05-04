require "test_helper"

class TransactionsDashboardTest < ActiveSupport::TestCase
  setup do
    @dashboard = TransactionsDashboard.new
  end

  test "stats returns a TransactionStats" do
    assert_instance_of TransactionStats, @dashboard.stats
  end

  test "stats is memoized" do
    assert_same @dashboard.stats, @dashboard.stats
  end

  test "recent_transactions includes existing transactions" do
    assert_includes @dashboard.recent_transactions, transactions(:lunch)
    assert_includes @dashboard.recent_transactions, transactions(:uber)
    assert_includes @dashboard.recent_transactions, transactions(:paycheck)
  end

  test "recent_transactions limits to RECENT_LIMIT and orders by recently_created" do
    Transaction.delete_all
    MonthlyPeriod.delete_all

    15.times do |i|
      Transaction.create!(
        amount: -10,
        date: Date.new(2026, 3, 1),
        category: categories(:food),
        created_by: users(:jaime),
        created_at: i.minutes.ago
      )
    end

    dashboard = TransactionsDashboard.new
    assert_equal TransactionsDashboard::RECENT_LIMIT, dashboard.recent_transactions.size
    timestamps = dashboard.recent_transactions.map(&:created_at)
    assert_equal timestamps.sort.reverse, timestamps
  end

  test "categories returns all categories ordered by name" do
    names = @dashboard.categories.map(&:name)
    assert_equal names.sort, names
    assert_includes names, "Food"
    assert_includes names, "Rideshare"
    assert_includes names, "Salary"
  end

  test "period_for returns the matching MonthlyPeriod for a transaction in a covered month" do
    period = @dashboard.period_for(transactions(:lunch))
    assert_equal monthly_periods(:march_2026), period
  end

  test "period_for returns nil for a transaction whose month has no period" do
    txn = transactions(:lunch)
    monthly_periods(:march_2026).delete

    assert_nil TransactionsDashboard.new.period_for(txn)
  end

  test "period_for handles an empty recent_transactions list" do
    txn = transactions(:lunch)
    Transaction.delete_all

    dashboard = TransactionsDashboard.new
    assert_empty dashboard.recent_transactions
    assert_nil dashboard.period_for(txn)
  end
end
