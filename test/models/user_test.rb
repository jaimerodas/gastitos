require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user can be created" do
    user = User.new(name: "Test", email: "test@example.com", password: "password123")
    assert user.valid?
  end

  test "requires a name" do
    user = User.new(name: "", email: "test@example.com", password: "password123")
    assert_not user.valid?
    assert user.errors[:name].any?
  end

  test "requires an email" do
    user = User.new(name: "Test", email: "", password: "password123")
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "requires a valid email format" do
    user = User.new(name: "Test", email: "not-an-email", password: "password123")
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "requires a unique email" do
    user = User.new(name: "Test", email: users(:jaime).email, password: "password123")
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "normalizes email to lowercase and stripped" do
    user = User.new(name: "Test", email: "  TEST@Example.COM  ", password: "password123")
    assert_equal "test@example.com", user.email
  end

  test "requires password of at least 8 characters" do
    user = User.new(name: "Test", email: "test@example.com", password: "short")
    assert_not user.valid?
    assert user.errors[:password].any?
  end

  test "authenticates with correct password" do
    user = users(:jaime)
    assert user.authenticate("password123")
  end

  test "does not authenticate with wrong password" do
    user = users(:jaime)
    assert_not user.authenticate("wrongpassword")
  end

  test "subsequent users are not admin or approved" do
    user = User.create!(name: "New", email: "new@example.com", password: "password123")
    assert_not user.admin?
    assert_not user.approved?
    assert user.viewer?
  end

  test "can_edit? returns true for editor" do
    assert users(:sofia).can_edit?
  end

  test "can_edit? returns true for admin" do
    assert users(:jaime).can_edit?
  end

  test "can_edit? returns false for viewer" do
    assert_not users(:viewer).can_edit?
  end

  test "role defaults to viewer" do
    user = User.new(name: "Test", email: "test@example.com", password: "password123")
    assert user.viewer?
  end

  test "rejects invalid role" do
    assert_raises(ArgumentError) do
      User.new(name: "Test", email: "test@example.com", password: "password123", role: "superadmin")
    end
  end
end
