class TransactionsController < ApplicationController
  before_action :require_login
  before_action :require_editor, only: [ :create, :edit, :update, :destroy ]

  def index
    @transaction = Transaction.new(date: Date.current)
    load_index_data
  end

  def create
    @transaction = Transaction.new(transaction_params)
    @transaction.created_by = current_user

    if @transaction.save
      ActivityLogger.log_transaction_created(current_user, @transaction)
      period = MonthlyPeriod.find_by!(year: @transaction.date.year, month: @transaction.date.month)
      redirect_to monthly_period_path(period)
    else
      @categories = Category.order(:name)
      return_to = params[:return_to]
      if return_to.present? && return_to.match(%r{\A/meses/(\d{4}-\d{2})\z})
        @period = MonthlyPeriod.find_by_slug!($1)
        @transactions = @period.transactions.recent.includes(:category, :created_by)
        @income_by_category = @period.income_by_category
        @expenses_by_category = @period.expenses_by_category
        render "monthly_periods/show", status: :unprocessable_entity
      else
        load_index_data
        render :index, status: :unprocessable_entity
      end
    end
  end

  def edit
    @transaction = Transaction.find(params[:id])
    @categories = Category.order(:name)
  end

  def update
    @transaction = Transaction.find(params[:id])

    if @transaction.update(transaction_params)
      ActivityLogger.log_transaction_updated(current_user, @transaction, @transaction.previous_changes)
      redirect_to safe_return_path
    else
      @categories = Category.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction = Transaction.find(params[:id])
    ActivityLogger.log_transaction_destroyed(current_user, @transaction)
    @transaction.destroy

    return_to = params[:return_to]
    if return_to.present? && return_to.match(%r{\A/meses/(\d{4}-\d{2})\z})
      period = MonthlyPeriod.find_by_slug!($1) rescue nil
      redirect_to period ? monthly_period_path(period) : monthly_periods_path
    else
      redirect_to root_path
    end
  end

  private

  def load_index_data
    @stats = TransactionStats.new
    @transactions = Transaction.recently_created.includes(:category, :created_by).limit(10)
    @categories = Category.order(:name)

    year_months = @transactions.map { |t| [ t.date.year, t.date.month ] }.uniq
    if year_months.any?
      conditions = year_months.map { "(year = ? AND month = ?)" }.join(" OR ")
      @periods_by_month = MonthlyPeriod.where(conditions, *year_months.flatten).index_by { |p| [ p.year, p.month ] }
    else
      @periods_by_month = {}
    end
  end

  def transaction_params
    params.expect(transaction: [ :amount, :date, :description, :category_id ])
  end

  def safe_return_path
    return_to = params[:return_to]
    if return_to.present? && return_to.match?(%r{\A/meses/\d{4}-\d{2}\z})
      return_to
    else
      root_path
    end
  end
end
