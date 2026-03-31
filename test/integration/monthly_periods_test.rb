require "test_helper"

class MonthlyPeriodsTest < ActionDispatch::IntegrationTest
  setup do
    log_in_as users(:jaime)
  end

  # -- Nav --

  test "nav shows months link when periods exist" do
    get root_path
    assert_select "a[href='#{monthly_periods_path}']", "Meses"
  end

  test "nav hides months link when no periods exist" do
    MonthlyPeriod.delete_all
    get root_path
    assert_select "a[href='#{monthly_periods_path}']", count: 0
  end

  # -- Index --

  test "index lists periods" do
    get monthly_periods_path
    assert_response :success
    assert_select "h1", "Meses"
    assert_select "a", monthly_periods(:march_2026).display_name
  end

  test "index requires login" do
    delete session_path
    get monthly_periods_path
    assert_redirected_to new_session_path
  end

  # -- Show --

  test "show displays P&L statement" do
    period = monthly_periods(:march_2026)
    get monthly_period_path(period)
    assert_response :success
    assert_select "h1", period.display_name
    assert_select "h2", "Resumen"
  end

  test "show displays starting balance" do
    period = monthly_periods(:march_2026)
    get monthly_period_path(period)
    assert_select "td", "Saldo inicial"
  end

  test "show displays income by category" do
    period = monthly_periods(:march_2026)
    get monthly_period_path(period)
    assert_select "th", "Ingresos"
    assert_select "td", "Salary"
  end

  test "show displays expenses by category" do
    period = monthly_periods(:march_2026)
    get monthly_period_path(period)
    assert_select "th", "Gastos"
    assert_select "td", "Food"
    assert_select "td", "Rideshare"
  end

  test "show lists transactions with category as edit link" do
    period = monthly_periods(:march_2026)
    get monthly_period_path(period)
    assert_select "h2", "Transacciones"
    assert_select "td a", text: "Food"
  end

  # -- Edit balance --

  test "edit shows starting balance form" do
    period = monthly_periods(:march_2026)
    get edit_monthly_period_path(period)
    assert_response :success
    assert_select "input[name='monthly_period[starting_balance]']"
  end

  test "update starting balance" do
    period = monthly_periods(:march_2026)
    patch monthly_period_path(period), params: { monthly_period: { starting_balance: 500 } }
    assert_redirected_to monthly_period_path(period)
    assert_equal 500.0, period.reload.starting_balance
  end

  # -- Delete transaction from show page --

  test "deleting a transaction redirects back to the period" do
    period = monthly_periods(:march_2026)
    txn = transactions(:lunch)
    assert_difference "Transaction.count", -1 do
      delete transaction_path(txn), params: { return_to: monthly_period_path(period) }
    end
    assert_redirected_to monthly_period_path(period)
  end

  test "deleting the last transaction in a period redirects to root" do
    # Create a lone transaction in February
    txn = Transaction.create!(
      amount: 10, date: Date.new(2026, 2, 5),
      category: categories(:food), created_by: users(:jaime)
    )
    feb_period = MonthlyPeriod.find_by(month: 2, year: 2026)
    assert feb_period

    delete transaction_path(txn)
    assert_nil MonthlyPeriod.find_by(month: 2, year: 2026)
    assert_redirected_to root_path
  end

  # -- return_to for transaction edit --

  test "edit transaction with return_to shows correct cancel link" do
    period = monthly_periods(:march_2026)
    txn = transactions(:lunch)
    get edit_transaction_path(txn, return_to: monthly_period_path(period))
    assert_select "a[href='#{monthly_period_path(period)}']", "Cancelar"
    assert_select "form[action='#{transaction_path(txn)}'] button", "Eliminar transacción"
  end

  test "update transaction with return_to redirects to period" do
    period = monthly_periods(:march_2026)
    txn = transactions(:lunch)
    patch transaction_path(txn), params: {
      return_to: monthly_period_path(period),
      transaction: {
        "date(1i)" => "2026", "date(2i)" => "3", "date(3i)" => "28",
        amount: "20.00",
        category_id: categories(:food).id,
        description: "Dinner"
      }
    }
    assert_redirected_to monthly_period_path(period)
  end

  test "update transaction with invalid return_to redirects to root" do
    txn = transactions(:lunch)
    patch transaction_path(txn), params: {
      return_to: "https://evil.com",
      transaction: {
        "date(1i)" => "2026", "date(2i)" => "3", "date(3i)" => "28",
        amount: "20.00",
        category_id: categories(:food).id
      }
    }
    assert_redirected_to root_path
  end

  # -- Auto-creation of periods --

  test "creating a transaction auto-creates a monthly period" do
    assert_difference "MonthlyPeriod.count", 1 do
      post transactions_path, params: { transaction: {
        "date(1i)" => "2026", "date(2i)" => "5", "date(3i)" => "15",
        amount: "25",
        category_id: categories(:food).id,
        description: "May expense"
      } }
    end
    assert MonthlyPeriod.find_by(month: 5, year: 2026)
  end

end
