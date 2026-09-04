class MultiPeriodReport
  MONTH_KEY = Arel.sql("strftime('%Y-%m', transactions.date)")

  def initialize(periods)
    @periods = periods
  end

  attr_reader :periods

  def income_categories
    grouped_amounts[:income].keys.map(&:last).uniq.sort
  end

  def expense_categories
    grouped_amounts[:expense].keys.map(&:last).uniq.sort
  end

  def amount_for(period, name)
    key = [ period.to_param, name ]
    grouped_amounts[:income][key] || grouped_amounts[:expense][key] || BigDecimal("0")
  end

  def total_income_for(period)
    sum_for_period(:income, period)
  end

  def total_expenses_for(period)
    sum_for_period(:expense, period)
  end

  def net_income_for(period)
    total_income_for(period) - total_expenses_for(period)
  end

  def ending_balance_for(period)
    period.starting_balance + net_income_for(period)
  end

  def total_for(name)
    periods.sum { |period| amount_for(period, name) }
  end

  def total_income
    periods.sum { |period| total_income_for(period) }
  end

  def total_expenses
    periods.sum { |period| total_expenses_for(period) }
  end

  def total_net_income
    periods.sum { |period| net_income_for(period) }
  end

  def gap_before(period)
    idx = periods.index(period)
    return nil if idx.nil? || idx.zero?

    cursor = periods[idx - 1].start_date.next_month
    missing = []
    while cursor < period.start_date
      missing << cursor
      cursor = cursor.next_month
    end
    missing.presence
  end

  private

  def sum_for_period(type, period)
    grouped_amounts[type].sum { |(month, _name), amount| month == period.to_param ? amount : BigDecimal("0") }
  end

  def grouped_amounts
    @grouped_amounts ||= begin
      income = {}
      expense = {}

      if periods.present?
        range = periods.first.start_date..periods.last.end_date

        Transaction.joins(:category)
                   .where(date: range)
                   .group(MONTH_KEY, "categories.category_type", "categories.name")
                   .sum(:amount)
                   .each do |(month, type, name), amount|
          key = [ month, name ]
          if type == "income"
            income[key] = amount
          else
            expense[key] = amount.abs
          end
        end
      end

      { income: income, expense: expense }
    end
  end
end
