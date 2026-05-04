class MonthlyPeriodReport
  def initialize(period)
    @period = period
  end

  attr_reader :period

  def transactions
    @transactions ||= period.transactions.recent.includes(:category, :created_by)
  end

  def income_by_category
    @income_by_category ||= period.income_by_category
  end

  def expenses_by_category
    @expenses_by_category ||= period.expenses_by_category
  end
end
