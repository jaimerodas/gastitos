class MonthlyPeriod < ApplicationRecord
  validates :month, presence: true, inclusion: { in: 1..12 }
  validates :year, presence: true
  validates :month, uniqueness: { scope: :year }

  scope :chronological, -> { order(year: :desc, month: :desc) }

  def transactions
    Transaction.where(date: start_date..end_date)
  end

  def net_income
    transactions.sum(:amount)
  end

  def ending_balance
    starting_balance + net_income
  end

  def income_by_category
    transactions.joins(:category)
                .where(categories: { category_type: "income" })
                .group("categories.name")
                .sum(:amount)
  end

  def expenses_by_category
    transactions.joins(:category)
                .where(categories: { category_type: "expense" })
                .group("categories.name")
                .sum(:amount)
  end

  def total_income
    transactions.joins(:category)
                .where(categories: { category_type: "income" })
                .sum(:amount)
  end

  def total_expenses
    transactions.joins(:category)
                .where(categories: { category_type: "expense" })
                .sum(:amount)
  end

  def display_name
    I18n.l(start_date, format: "%B %Y").capitalize
  end

  def self.find_or_create_for_date(date)
    find_or_create_by(month: date.month, year: date.year) do |period|
      period.starting_balance = default_starting_balance_for(date.month, date.year)
    end
  end

  private

  def start_date
    Date.new(year, month, 1)
  end

  def end_date
    start_date.end_of_month
  end

  def self.default_starting_balance_for(month, year)
    previous = where("year < ? OR (year = ? AND month < ?)", year, year, month)
                 .order(year: :desc, month: :desc)
                 .first
    previous ? previous.ending_balance : 0
  end
end
