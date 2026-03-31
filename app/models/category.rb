class Category < ApplicationRecord
  TYPES = %w[expense income].freeze

  has_many :transactions, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :category_type, presence: true, inclusion: { in: TYPES }

  scope :expenses, -> { where(category_type: "expense") }
  scope :income, -> { where(category_type: "income") }

  def expense?
    category_type == "expense"
  end

  def income?
    category_type == "income"
  end
end
