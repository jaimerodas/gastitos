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
end
