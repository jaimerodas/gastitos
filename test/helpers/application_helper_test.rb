require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # -- amount_class --

  test "amount_class returns expense class for negative amount" do
    assert_equal "amount-expense", amount_class(-12.50)
  end

  test "amount_class returns income class for zero amount" do
    assert_equal "amount-income", amount_class(0)
  end

  test "amount_class returns income class for positive amount" do
    assert_equal "amount-income", amount_class(12.50)
  end

  # -- month_run_label --

  test "month_run_label returns single month name for one date" do
    assert_equal "abril", month_run_label([ Date.new(2026, 4, 1) ])
  end

  test "month_run_label returns range for a run of months" do
    dates = [ Date.new(2026, 4, 1), Date.new(2026, 5, 1), Date.new(2026, 6, 1) ]
    assert_equal "abril–junio", month_run_label(dates)
  end

  test "month_run_label handles a cross-year run" do
    dates = [ Date.new(2025, 12, 1), Date.new(2026, 1, 1) ]
    assert_equal "diciembre–enero", month_run_label(dates)
  end

  test "amount_cell renders a muted dash for zero" do
    assert_dom_equal %(<td class="money amount-expense zero">—</td>), amount_cell(BigDecimal("0"), "money amount-expense")
  end

  test "amount_cell renders currency for a non-zero amount" do
    assert_dom_equal %(<td class="money amount-income">$1,234.50</td>), amount_cell(BigDecimal("1234.5"), "money amount-income")
  end
end
