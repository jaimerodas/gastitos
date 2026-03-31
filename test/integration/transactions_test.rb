require "test_helper"

class TransactionsTest < ActionDispatch::IntegrationTest
  setup do
    log_in_as users(:jaime)
  end

  # -- Index --

  test "index shows transaction form" do
    get root_path
    assert_response :success
    assert_select "h2", "Nueva transacción"
    assert_select "form[action='#{transactions_path}']"
  end

  test "index shows recent transactions" do
    get root_path
    assert_select "table tbody tr", count: 3
  end

  test "index shows dates in YYYY-MM-DD format with month linked to period" do
    get root_path
    period = monthly_periods(:march_2026)
    txn = transactions(:lunch)
    assert_select "td a[href='#{monthly_period_path(period)}']", txn.date.strftime("%Y-%m")
  end

  test "index shows no table when there are no transactions" do
    Transaction.delete_all
    get root_path
    assert_select "table", count: 0
  end

  test "date is prefilled with today" do
    get root_path
    # Day select (3i) should have today's day selected
    assert_select "select[name='transaction[date(3i)]'] option[selected]", Date.current.day.to_s
  end


  # -- Create --

  test "creating a valid expense transaction" do
    assert_difference "Transaction.count", 1 do
      post transactions_path, params: { transaction: {
        "date(1i)" => "2026", "date(2i)" => "3", "date(3i)" => "30",
        amount: "15.50",
        category_id: categories(:food).id,
        description: "Lunch"
      } }
    end
    txn = Transaction.last
    assert_redirected_to monthly_period_path(MonthlyPeriod.find_by(year: 2026, month: 3))

    assert_equal Date.new(2026, 3, 30), txn.date
    assert_equal(-15.50, txn.amount)
    assert_equal categories(:food), txn.category
    assert_equal users(:jaime), txn.created_by
    assert_equal "Lunch", txn.description
  end

  test "creating a valid income transaction" do
    assert_difference "Transaction.count", 1 do
      post transactions_path, params: { transaction: {
        "date(1i)" => "2026", "date(2i)" => "3", "date(3i)" => "1",
        amount: "500",
        category_id: categories(:salary).id,
        description: "Bonus"
      } }
    end

    txn = Transaction.last
    assert_equal 500.0, txn.amount
  end

  test "creating a transaction with invalid data re-renders form" do
    assert_no_difference "Transaction.count" do
      post transactions_path, params: { transaction: {
        "date(1i)" => "2026", "date(2i)" => "3", "date(3i)" => "30",
        amount: "",
        category_id: "",
        description: ""
      } }
    end
    assert_response :unprocessable_entity
    assert_select "section[role=alert]"
  end

  # -- Edit --

  test "index shows edit links for each transaction" do
    get root_path
    assert_select "a[href='#{edit_transaction_path(transactions(:lunch))}']", /Food/
  end

  test "edit page shows form with existing values" do
    txn = transactions(:lunch)
    get edit_transaction_path(txn)
    assert_response :success
    assert_select "h2", "Editar transacción"
    assert_select "select[name='transaction[date(3i)]'] option[selected]", txn.date.day.to_s
    assert_select "input[name='transaction[amount]'][value='12.5']"
  end

  test "edit page has a cancel link" do
    get edit_transaction_path(transactions(:lunch))
    assert_select "a[href='#{root_path}']", "Cancelar"
  end

  test "edit page has a delete button" do
    txn = transactions(:lunch)
    get edit_transaction_path(txn)
    assert_select "form[action='#{transaction_path(txn)}'] button", "Eliminar transacción"
  end

  test "updating a transaction with valid data" do
    txn = transactions(:lunch)
    patch transaction_path(txn), params: { transaction: {
      "date(1i)" => "2026", "date(2i)" => "3", "date(3i)" => "28",
      amount: "20.00",
      category_id: categories(:food).id,
      description: "Dinner"
    } }
    assert_redirected_to root_path

    txn.reload
    assert_equal(-20.0, txn.amount)
    assert_equal "Dinner", txn.description
  end

  test "updating a transaction with invalid data re-renders form" do
    txn = transactions(:lunch)
    patch transaction_path(txn), params: { transaction: {
      amount: "",
      category_id: ""
    } }
    assert_response :unprocessable_entity
    assert_select "section[role=alert]"
  end

  # -- Auth --

  test "creating a transaction requires login" do
    delete session_path
    post transactions_path, params: { transaction: { amount: "10" } }
    assert_redirected_to new_session_path
  end
end
