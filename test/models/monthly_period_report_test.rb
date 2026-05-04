require "test_helper"

class MonthlyPeriodReportTest < ActiveSupport::TestCase
  setup do
    @period = monthly_periods(:march_2026)
    @report = MonthlyPeriodReport.new(@period)
  end

  test "exposes the period it wraps" do
    assert_equal @period, @report.period
  end

  test "transactions returns the period's transactions ordered by recent" do
    txns = @report.transactions
    assert_includes txns, transactions(:lunch)
    assert_includes txns, transactions(:uber)
    assert_includes txns, transactions(:paycheck)

    dates = txns.map(&:date)
    assert_equal dates.sort.reverse, dates
  end

  test "transactions eager-loads category and created_by" do
    @report.transactions.to_a # force load
    assert_no_queries do
      @report.transactions.each do |txn|
        txn.category.name
        txn.created_by.name
      end
    end
  end

  test "income_by_category delegates to the period" do
    assert_equal @period.income_by_category, @report.income_by_category
  end

  test "expenses_by_category delegates to the period" do
    assert_equal @period.expenses_by_category, @report.expenses_by_category
  end

  test "memoizes its readers" do
    assert_same @report.transactions, @report.transactions
    assert_same @report.income_by_category, @report.income_by_category
    assert_same @report.expenses_by_category, @report.expenses_by_category
  end
end
