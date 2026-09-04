class Category < ApplicationRecord
  has_many :transactions, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  enum :category_type, { expense: "expense", income: "income" }, validate: true
end
