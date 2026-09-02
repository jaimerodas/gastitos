require "test_helper"

class MonthlyPeriodSummaryTest < ActionDispatch::IntegrationTest
  setup do
    log_in_as users(:jaime)
  end

  def create_periods!
    # Auto-creates 2025-11 and 2025-12 via transactions
    Transaction.create!(amount: 100, date: Date.new(2025, 11, 5), category: categories(:food), created_by: users(:jaime))
    Transaction.create!(amount: 500, date: Date.new(2025, 12, 1), category: categories(:salary), created_by: users(:jaime))
    MonthlyPeriod.create!(month: 1, year: 2026, starting_balance: 0)
    MonthlyPeriod.create!(month: 4, year: 2026, starting_balance: 0)
    MonthlyPeriod.create!(month: 5, year: 2026, starting_balance: 0)
  end

  test "requires login" do
    delete session_path
    get summary_monthly_periods_path
    assert_redirected_to new_session_path
  end

  test "default shows the last 3 months" do
    create_periods!
    get summary_monthly_periods_path
    assert_response :success
    assert_select "thead th a", count: 3
    assert_select "thead th a[href=?]", monthly_period_path(MonthlyPeriod.find_by_slug!("2026-05")), text: "May 2026"
    assert_select "thead th a[href=?]", monthly_period_path(MonthlyPeriod.find_by_slug!("2025-11")), count: 0
  end

  test "shows a Total column header and no average column" do
    create_periods!
    get summary_monthly_periods_path
    assert_select "thead th", text: "Total"
    assert_select "thead th", text: "Promedio", count: 0
  end

  test "shows P&L row labels" do
    create_periods!
    get summary_monthly_periods_path
    assert_select "tbody td", text: "Saldo inicial"
    assert_select "tbody td", text: "Total ingresos"
    assert_select "tbody td", text: "Total gastos"
    assert_select "tbody td", text: "Resultado neto"
    assert_select "tbody td", text: "Saldo final"
  end

  test "default size link is marked current" do
    create_periods!
    get summary_monthly_periods_path
    assert_select "a[href=?][aria-current=page]", summary_monthly_periods_path(meses: 3), text: "Últimos 3"
  end

  test "meses=6 shows 6 months and marks Ultimos 6 current" do
    create_periods!
    get summary_monthly_periods_path(meses: 6)
    assert_select "thead th a", count: 6
    assert_select "a[aria-current=page]", text: "Últimos 6"
  end

  test "meses=todos shows all periods, marks Todos current, and hides pager" do
    create_periods!
    get summary_monthly_periods_path(meses: "todos")
    assert_select "thead th a", count: 6
    assert_select "a[aria-current=page]", text: "Todos"
    assert_select ".pager", count: 0
  end

  test "invalid meses value falls back to default of 3" do
    create_periods!
    get summary_monthly_periods_path(meses: 99)
    assert_select "thead th a", count: 3
  end

  test "default page has an older link and no newer link" do
    create_periods!
    get summary_monthly_periods_path
    assert_select "a[rel=prev][href=?]", summary_monthly_periods_path(meses: "3", hasta: "2026-01")
    assert_select "a[rel=next]", count: 0
  end

  test "following the older link shows the previous window with a newer link back" do
    create_periods!
    get summary_monthly_periods_path(meses: "3", hasta: "2026-01")
    assert_select "thead th a", text: "Nov 2025"
    assert_select "thead th a", text: "Dic 2025"
    assert_select "thead th a", text: "Ene 2026"
    assert_select "a[rel=next][href=?]", summary_monthly_periods_path(meses: "3", hasta: "2026-05")
    assert_select "a[rel=prev]", count: 0
  end

  test "gap caption shows when the window spans the missing February" do
    create_periods!
    get summary_monthly_periods_path(meses: 6)
    assert_select "thead th.gap-after small.gap-caption", text: "sin datos: febrero"
  end

  test "no gap caption when the window has no missing months" do
    create_periods!
    get summary_monthly_periods_path(meses: "3", hasta: "2026-01")
    assert_select ".gap-after", count: 0
  end

  test "meses=todos shows exactly one gap caption" do
    create_periods!
    get summary_monthly_periods_path(meses: "todos")
    assert_select ".gap-caption", count: 1
  end

  test "amounts render for category rows and totals" do
    create_periods!
    get summary_monthly_periods_path(meses: "3", hasta: "2026-01")
    assert_select "tbody td", text: "Food"
    assert_select "td.money.amount-expense", text: "$100.00"
    assert_select "td.summary-col", text: "$500.00"
  end

  test "balance rows leave summary cells blank" do
    create_periods!
    get summary_monthly_periods_path
    assert_select "tr.ending td.summary-col", count: 1 do |elements|
      elements.each { |el| assert_equal "", el.text.strip }
    end
  end

  test "empty state renders with no periods" do
    MonthlyPeriod.delete_all
    get summary_monthly_periods_path
    assert_response :success
    assert_select "p.empty-state"
    assert_select "table", count: 0
  end

  test "nav marks Resumen current on the summary page and Meses not current" do
    create_periods!
    get summary_monthly_periods_path
    assert_select "nav a[href=?][aria-current=page]", summary_monthly_periods_path, text: "Resumen"
    assert_select "nav a[href=?][aria-current]", monthly_periods_path, count: 0
  end

  test "nav marks Meses current on the index page and shows Resumen not current" do
    create_periods!
    get monthly_periods_path
    assert_select "nav a[href=?][aria-current=page]", monthly_periods_path, text: "Meses"
    assert_select "nav a[href=?]", summary_monthly_periods_path, text: "Resumen"
    assert_select "nav a[href=?][aria-current]", summary_monthly_periods_path, count: 0
  end

  test "index page links to the summary page" do
    create_periods!
    get monthly_periods_path
    assert_select "a[href=?]", summary_monthly_periods_path, text: "Resumen de varios meses"
  end

  test "category cells with no activity render a muted dash instead of $0.00" do
    create_periods!
    get summary_monthly_periods_path(meses: "3", hasta: "2026-01")
    # Food (Nov only) and Salary (Dic only) across Nov/Dic/Ene leave 4 empty category cells
    assert_select "td.money.zero", text: "—", count: 4
  end
end
