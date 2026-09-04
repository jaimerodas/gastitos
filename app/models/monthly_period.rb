class MonthlyPeriod < ApplicationRecord
  validates :month, presence: true, inclusion: { in: 1..12 }
  validates :year, presence: true
  validates :month, uniqueness: { scope: :year }

  scope :chronological, -> { order(year: :desc, month: :desc) }

  def to_param
    "#{year}-#{"%02d" % month}"
  end

  def self.find_by_slug!(slug)
    year, month = slug.split("-").map(&:to_i)
    find_by!(year: year, month: month)
  end

  def start_date
    Date.new(year, month, 1)
  end

  def end_date
    start_date.end_of_month
  end

  def date_range
    start_date..end_date
  end

  def transactions
    Transaction.where(date: date_range)
  end

  def recent_transactions
    transactions.recent.includes(:category, :created_by)
  end

  # The current month and the two before it. Older months get the
  # transaction form collapsed, since they are mostly read, not edited.
  RECENT_MONTHS = 3

  def recent?(today: Date.current)
    start_date >= today.beginning_of_month.prev_month(RECENT_MONTHS - 1)
  end

  def net_income
    transactions.sum(:amount)
  end

  def ending_balance
    starting_balance + net_income
  end

  def income_by_category
    by_category("income")
  end

  def expenses_by_category
    by_category("expense")
  end

  def total_income
    by_category("income").values.sum
  end

  def total_expenses
    by_category("expense").values.sum
  end

  def display_name
    I18n.l(start_date, format: "%B %Y").capitalize
  end

  def display_month
    I18n.l(start_date, format: "%B").capitalize
  end

  def short_name
    I18n.l(start_date, format: "%b %Y").capitalize
  end

  def self.find_or_create_for_date(date)
    find_or_create_by(month: date.month, year: date.year) do |period|
      period.starting_balance = default_starting_balance_for(date.month, date.year)
    end
  end

  private

  def by_category(type)
    @by_category ||= {}
    @by_category[type] ||= transactions.joins(:category)
                                        .where(categories: { category_type: type })
                                        .group("categories.name")
                                        .sum(:amount)
  end

  def self.default_starting_balance_for(month, year)
    previous = where("year < ? OR (year = ? AND month < ?)", year, year, month)
                 .order(year: :desc, month: :desc)
                 .first
    previous ? previous.ending_balance : 0
  end
end
