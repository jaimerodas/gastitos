require "test_helper"

class CategoriesTest < ActionDispatch::IntegrationTest
  setup do
    log_in_as users(:jaime)
  end

  test "creating a valid category returns JSON" do
    assert_difference "Category.count", 1 do
      post categories_path, params: { category: { name: "Groceries", category_type: "expense" } },
           as: :json
    end
    assert_response :created

    body = response.parsed_body
    assert_equal "Groceries", body["name"]
    assert_equal "expense", body["category_type"]
    assert body["id"].present?
  end

  test "creating a category with invalid data returns errors" do
    assert_no_difference "Category.count" do
      post categories_path, params: { category: { name: "", category_type: "bogus" } },
           as: :json
    end
    assert_response :unprocessable_entity

    body = response.parsed_body
    assert body["errors"].any?
  end

  test "creating a duplicate category returns errors" do
    assert_no_difference "Category.count" do
      post categories_path, params: { category: { name: "Food", category_type: "expense" } },
           as: :json
    end
    assert_response :unprocessable_entity
  end

  test "creating a category requires login" do
    delete session_path
    post categories_path, params: { category: { name: "Test", category_type: "expense" } },
         as: :json
    assert_redirected_to new_session_path
  end
end
