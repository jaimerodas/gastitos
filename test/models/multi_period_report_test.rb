require "test_helper"

class MultiPeriodReportTest < ActiveSupport::TestCase
  setup do
    create_txn(100, Date.new(2025, 11, 5), :food)     # creates period 2025-11
    create_txn(500, Date.new(2025, 12, 1), :salary)   # creates 2025-12
    create_txn(50,  Date.new(2025, 12, 9), :food)
    @periods = MonthlyPeriod.chronological.reverse # [ 2025-11, 2025-12, 2026-03 ]
    @nov, @dec, @mar = @periods
    @report = MultiPeriodReport.new(@periods)
  end

  test "income_categories lists sorted category names with income activity in any shown period" do
    assert_equal [ "Salary" ], @report.income_categories
  end

  test "expense_categories lists sorted category names with expense activity in any shown period" do
    assert_equal [ "Food", "Rideshare" ], @report.expense_categories
  end

  test "amount_for returns the amount for a period and category with activity" do
    assert_equal 100, @report.amount_for(@nov, "Food")
  end

  test "amount_for returns zero for a period and category with no activity" do
    assert_equal 0, @report.amount_for(@nov, "Rideshare")
  end

  test "amount_for returns income amounts as positive" do
    assert_equal 1000, @report.amount_for(@mar, "Salary")
  end

  test "amount_for returns a BigDecimal for a present cell" do
    assert_kind_of BigDecimal, @report.amount_for(@nov, "Food")
  end

  test "amount_for returns a BigDecimal for a missing cell" do
    assert_kind_of BigDecimal, @report.amount_for(@nov, "Rideshare")
  end

  test "total_income_for sums a period's income" do
    assert_equal 500, @report.total_income_for(@dec)
  end

  test "total_expenses_for sums a period's expenses as a positive amount" do
    assert_equal 50, @report.total_expenses_for(@dec)
  end

  test "net_income_for is income minus expenses for a period" do
    assert_equal 450, @report.net_income_for(@dec)
  end

  test "net_income_for is negative when a period has only expenses" do
    assert_equal(-100, @report.net_income_for(@nov))
  end

  test "ending_balance_for matches the period's own ending balance" do
    @periods.each do |period|
      assert_equal period.ending_balance, @report.ending_balance_for(period)
    end
  end

  test "total_for sums a category across every shown period" do
    assert_equal 162.50, @report.total_for("Food")
  end

  test "total_income sums income across every shown period" do
    assert_equal 1500, @report.total_income
  end

  test "total_net_income sums net income across every shown period" do
    assert_equal 1329.50, @report.total_net_income
  end

  test "gap_before is nil for the first shown period" do
    assert_nil @report.gap_before(@nov)
  end

  test "gap_before is nil when the previous shown period is adjacent" do
    assert_nil @report.gap_before(@dec)
  end

  test "gap_before lists the first day of each missing month between shown periods" do
    assert_equal [ Date.new(2026, 1, 1), Date.new(2026, 2, 1) ], @report.gap_before(@mar)
  end

  test "totals only cover the periods passed in, not every period in the database" do
    report = MultiPeriodReport.new([ @nov, @mar ])
    assert_equal 1000, report.total_income
  end

  test "gap_before counts every missing month in a wider subset window" do
    report = MultiPeriodReport.new([ @nov, @mar ])
    assert_equal 3, report.gap_before(@mar).size
  end

  test "an empty period list produces empty results with no query" do
    report = MultiPeriodReport.new([])

    assert_no_queries do
      assert_empty report.income_categories
      assert_equal 0, report.total_income
      assert_nil report.gap_before(@mar)
    end
  end

  test "runs a single query no matter how many readers are called" do
    assert_queries_count(1) do
      @report.income_categories
      @report.expense_categories
      @periods.each do |period|
        @report.amount_for(period, "Food")
        @report.ending_balance_for(period)
      end
      @report.total_net_income
      @report.gap_before(@periods.last)
    end
  end

  private

  def create_txn(amount, date, category_sym)
    Transaction.create!(amount: amount, date: date, category: categories(category_sym), created_by: users(:jaime))
  end
end
