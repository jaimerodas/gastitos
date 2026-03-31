require "test_helper"

class MonthlyPeriodTest < ActiveSupport::TestCase
  test "valid period" do
    period = MonthlyPeriod.new(month: 1, year: 2026, starting_balance: 0)
    assert period.valid?
  end

  test "requires month" do
    period = MonthlyPeriod.new(month: nil, year: 2026)
    assert_not period.valid?
  end

  test "month must be between 1 and 12" do
    assert_not MonthlyPeriod.new(month: 0, year: 2026).valid?
    assert_not MonthlyPeriod.new(month: 13, year: 2026).valid?
    assert MonthlyPeriod.new(month: 1, year: 2026).valid?
    assert MonthlyPeriod.new(month: 12, year: 2026).valid?
  end

  test "requires year" do
    period = MonthlyPeriod.new(month: 1, year: nil)
    assert_not period.valid?
  end

  test "month and year must be unique together" do
    duplicate = MonthlyPeriod.new(
      month: monthly_periods(:march_2026).month,
      year: monthly_periods(:march_2026).year
    )
    assert_not duplicate.valid?
  end

  test "transactions returns only transactions in the period" do
    period = monthly_periods(:march_2026)
    txns = period.transactions
    assert txns.include?(transactions(:lunch))
    assert txns.include?(transactions(:uber))
    assert txns.include?(transactions(:paycheck))
  end

  test "net_income sums all transactions" do
    period = monthly_periods(:march_2026)
    expected = transactions(:lunch).amount + transactions(:uber).amount + transactions(:paycheck).amount
    assert_equal expected, period.net_income
  end

  test "ending_balance adds net_income to starting_balance" do
    period = monthly_periods(:march_2026)
    assert_equal period.starting_balance + period.net_income, period.ending_balance
  end

  test "income_by_category groups income transactions" do
    period = monthly_periods(:march_2026)
    result = period.income_by_category
    assert_equal transactions(:paycheck).amount, result["Salary"]
  end

  test "expenses_by_category groups expense transactions" do
    period = monthly_periods(:march_2026)
    result = period.expenses_by_category
    assert_equal transactions(:lunch).amount, result["Food"]
    assert_equal transactions(:uber).amount, result["Rideshare"]
  end

  test "display_name returns localized month and year" do
    period = monthly_periods(:march_2026)
    assert_equal "Marzo 2026", period.display_name
  end

  test "find_or_create_for_date returns existing period" do
    existing = monthly_periods(:march_2026)
    found = MonthlyPeriod.find_or_create_for_date(Date.new(2026, 3, 15))
    assert_equal existing, found
  end

  test "find_or_create_for_date creates new period" do
    assert_difference "MonthlyPeriod.count", 1 do
      period = MonthlyPeriod.find_or_create_for_date(Date.new(2026, 1, 1))
      assert_equal 1, period.month
      assert_equal 2026, period.year
    end
  end

  test "first period ever gets starting_balance of 0" do
    MonthlyPeriod.delete_all
    period = MonthlyPeriod.find_or_create_for_date(Date.new(2025, 6, 1))
    assert_equal 0, period.starting_balance
  end

  test "new period defaults to previous period ending_balance" do
    march = monthly_periods(:march_2026)
    april = MonthlyPeriod.find_or_create_for_date(Date.new(2026, 4, 1))
    assert_equal march.ending_balance, april.starting_balance
  end

  test "new period with gap uses most recent previous period" do
    march = monthly_periods(:march_2026)
    june = MonthlyPeriod.find_or_create_for_date(Date.new(2026, 6, 1))
    assert_equal march.ending_balance, june.starting_balance
  end

  test "to_param returns YYYY-MM format" do
    period = monthly_periods(:march_2026)
    assert_equal "2026-03", period.to_param
  end

  test "find_by_slug! finds period by YYYY-MM slug" do
    period = MonthlyPeriod.find_by_slug!("2026-03")
    assert_equal monthly_periods(:march_2026), period
  end

  test "find_by_slug! raises when not found" do
    assert_raises(ActiveRecord::RecordNotFound) do
      MonthlyPeriod.find_by_slug!("2099-01")
    end
  end

  test "chronological scope orders newest first" do
    MonthlyPeriod.find_or_create_for_date(Date.new(2026, 1, 1))
    periods = MonthlyPeriod.chronological
    assert periods.first.month >= periods.last.month || periods.first.year > periods.last.year
  end
end
