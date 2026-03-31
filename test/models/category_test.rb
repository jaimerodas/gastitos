require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "valid expense category" do
    category = Category.new(name: "Clothes", category_type: "expense")
    assert category.valid?
  end

  test "valid income category" do
    category = Category.new(name: "Freelance", category_type: "income")
    assert category.valid?
  end

  test "requires a name" do
    category = Category.new(name: "", category_type: "expense")
    assert_not category.valid?
  end

  test "requires a unique name" do
    category = Category.new(name: categories(:food).name, category_type: "expense")
    assert_not category.valid?
  end

  test "requires a valid category_type" do
    category = Category.new(name: "Other", category_type: "bogus")
    assert_not category.valid?
  end

  test "expense? returns true for expense categories" do
    assert categories(:food).expense?
    assert_not categories(:food).income?
  end

  test "income? returns true for income categories" do
    assert categories(:salary).income?
    assert_not categories(:salary).expense?
  end
end
