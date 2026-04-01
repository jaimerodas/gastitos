require "test_helper"

class ViewerAccessTest < ActionDispatch::IntegrationTest
  setup do
    @viewer = users(:viewer)
    log_in_as @viewer
  end

  # === Read access ===

  test "viewer can see transaction index" do
    get root_path
    assert_response :success
  end

  test "viewer can see monthly periods index" do
    get monthly_periods_path
    assert_response :success
  end

  test "viewer can see monthly period show" do
    period = monthly_periods(:march_2026)
    get monthly_period_path(period)
    assert_response :success
  end

  # === No forms visible ===

  test "viewer does not see transaction form on index" do
    get root_path
    assert_select "form[action=?]", transactions_path, count: 0
  end

  test "viewer does not see transaction form on monthly period show" do
    period = monthly_periods(:march_2026)
    get monthly_period_path(period)
    assert_select "form[action=?]", transactions_path, count: 0
  end

  test "viewer does not see edit links for transactions on index" do
    get root_path
    assert_select "a[href^=?]", "/transactions/", count: 0
  end

  test "viewer does not see starting balance edit link" do
    period = monthly_periods(:march_2026)
    get monthly_period_path(period)
    assert_select "a[href=?]", edit_monthly_period_path(period), count: 0
  end

  # === Write access blocked ===

  test "viewer cannot create transaction" do
    assert_no_difference "Transaction.count" do
      post transactions_path, params: { transaction: { amount: 100, date: Date.current, category_id: categories(:food).id } }
    end
    assert_redirected_to root_path
  end

  test "viewer cannot access edit transaction page" do
    get edit_transaction_path(transactions(:lunch))
    assert_redirected_to root_path
  end

  test "viewer cannot update transaction" do
    patch transaction_path(transactions(:lunch)), params: { transaction: { amount: 999 } }
    assert_redirected_to root_path
  end

  test "viewer cannot destroy transaction" do
    assert_no_difference "Transaction.count" do
      delete transaction_path(transactions(:lunch))
    end
    assert_redirected_to root_path
  end

  test "viewer cannot create category" do
    assert_no_difference "Category.count" do
      post categories_path, params: { category: { name: "New", category_type: "expense" } }
    end
    assert_redirected_to root_path
  end

  test "viewer cannot access edit monthly period page" do
    period = monthly_periods(:march_2026)
    get edit_monthly_period_path(period)
    assert_redirected_to root_path
  end

  test "viewer cannot update monthly period" do
    period = monthly_periods(:march_2026)
    patch monthly_period_path(period), params: { monthly_period: { starting_balance: 9999 } }
    assert_redirected_to root_path
  end

  # === Admin pages blocked ===

  test "viewer cannot access users index" do
    get users_path
    assert_redirected_to root_path
  end

  test "viewer cannot access user show" do
    get user_path(users(:jaime))
    assert_redirected_to root_path
  end
end
