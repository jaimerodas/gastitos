require "test_helper"

class TransactionStatsTest < ActiveSupport::TestCase
  setup do
    @stats = TransactionStats.new
  end

  test "any? returns true when expense transactions exist" do
    assert @stats.any?
  end

  test "any? returns false when no expense transactions exist" do
    Transaction.where("amount < 0").delete_all
    assert_not @stats.any?
  end

  test "total_spend sums absolute value of expense transactions" do
    # Fixtures: lunch (-12.50) + uber (-8.00) = 20.50
    assert_equal 20.50, @stats.total_spend
  end

  test "average_monthly_spend divides total by distinct months" do
    # All expense fixtures are in March 2026 — one month
    assert_equal 20.50, @stats.average_monthly_spend
  end

  test "average_monthly_spend across multiple months" do
    # Add an expense in a different month
    Transaction.create!(
      amount: -30,
      date: Date.new(2026, 4, 15),
      category: categories(:food),
      created_by: users(:jaime)
    )
    # Total: 20.50 + 30 = 50.50, across 2 months
    assert_equal 25.25, @stats.average_monthly_spend
  end

  test "average_monthly_spend returns zero with no expenses" do
    Transaction.where("amount < 0").delete_all
    assert_equal 0, @stats.average_monthly_spend
  end

  test "top_categories returns categories ranked by spend" do
    result = @stats.top_categories
    assert_equal 2, result.length
    assert_equal "Food", result.first[:name]
    assert_equal 12.50, result.first[:total]
    assert_equal "Rideshare", result.second[:name]
    assert_equal 8.00, result.second[:total]
  end

  test "top_categories limits results" do
    result = @stats.top_categories(1)
    assert_equal 1, result.length
  end

  test "top_categories returns empty array with no expenses" do
    Transaction.where("amount < 0").delete_all
    assert_empty @stats.top_categories
  end
end
