class TransactionsController < ApplicationController
  before_action :require_login
  before_action :require_editor, only: [ :create, :edit, :update, :destroy ]

  def index
    @transaction = Transaction.new(date: Date.current)
    @dashboard = TransactionsDashboard.new
  end

  def create
    @transaction = Transaction.new(transaction_params)
    @transaction.created_by = current_user

    if @transaction.save
      ActivityLogger.log(current_user, :transaction_created, @transaction)
      period = MonthlyPeriod.find_by!(year: @transaction.date.year, month: @transaction.date.month)
      redirect_to monthly_period_path(period)
    else
      if (period = period_from_return_to)
        @period_report = MonthlyPeriodReport.new(period)
        @categories = Category.order(:name)
        render "monthly_periods/show", status: :unprocessable_entity
      else
        @dashboard = TransactionsDashboard.new
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
      ActivityLogger.log(current_user, :transaction_updated, @transaction)
      redirect_to safe_return_path
    else
      @categories = Category.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction = Transaction.find(params[:id])
    ActivityLogger.log(current_user, :transaction_destroyed, @transaction)
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

  def period_from_return_to
    return unless params[:return_to].to_s.match(%r{\A/meses/(\d{4}-\d{2})\z})
    MonthlyPeriod.find_by_slug!($1)
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
