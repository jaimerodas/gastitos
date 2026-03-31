class Transaction < ApplicationRecord
  belongs_to :category
  belongs_to :created_by, class_name: "User"

  validates :amount, presence: true, numericality: { other_than: 0 }
  validates :date, presence: true
  validates :description, length: { maximum: 140 }, allow_blank: true

  before_validation :apply_sign_from_category
  after_save :ensure_monthly_period
  after_save :cleanup_old_monthly_period, if: :saved_change_to_date?
  after_destroy :cleanup_monthly_period

  scope :recent, -> { order(date: :desc, created_at: :desc) }

  private

  def apply_sign_from_category
    return unless amount.present? && category.present?

    self.amount = -amount.abs if category.expense?
    self.amount = amount.abs if category.income?
  end

  def ensure_monthly_period
    MonthlyPeriod.find_or_create_for_date(date)
  end

  def cleanup_old_monthly_period
    old_date = date_before_last_save
    return if old_date.nil?
    return if old_date.month == date.month && old_date.year == date.year

    old_period = MonthlyPeriod.find_by(month: old_date.month, year: old_date.year)
    old_period.destroy if old_period && old_period.transactions.empty?
  end

  def cleanup_monthly_period
    period = MonthlyPeriod.find_by(month: date.month, year: date.year)
    period.destroy if period && period.transactions.empty?
  end
end
