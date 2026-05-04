class TransactionsDashboard
  RECENT_LIMIT = 10

  def stats
    @stats ||= TransactionStats.new
  end

  def recent_transactions
    @recent_transactions ||=
      Transaction.recently_created.includes(:category, :created_by).limit(RECENT_LIMIT)
  end

  def categories
    @categories ||= Category.order(:name)
  end

  def period_for(transaction)
    periods_by_month[[ transaction.date.year, transaction.date.month ]]
  end

  private

  def periods_by_month
    @periods_by_month ||= begin
      year_months = recent_transactions.map { |t| [ t.date.year, t.date.month ] }.uniq
      if year_months.any?
        conditions = year_months.map { "(year = ? AND month = ?)" }.join(" OR ")
        MonthlyPeriod.where(conditions, *year_months.flatten).index_by { |p| [ p.year, p.month ] }
      else
        {}
      end
    end
  end
end
