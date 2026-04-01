class TransactionStats
  def any?
    expense_scope.exists?
  end

  def total_spend
    expense_scope.sum(:amount).abs
  end

  def average_monthly_spend
    total = total_spend
    months = expense_scope.distinct.count(Arel.sql("strftime('%Y-%m', date)"))
    months > 0 ? total / months : 0
  end

  def top_categories(limit = 3)
    expense_scope
      .joins(:category)
      .group("categories.name")
      .order(Arel.sql("SUM(amount)"))
      .limit(limit)
      .pluck("categories.name", Arel.sql("ABS(SUM(amount))"))
      .map { |name, total| { name: name, total: total } }
  end

  private

  def expense_scope
    Transaction.where("amount < 0")
  end
end
