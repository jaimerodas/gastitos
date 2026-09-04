class TransactionsController < ApplicationController
  RETURN_TO_MONTH = %r{\A/meses/(\d{4})-(\d{2})\z}

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
      redirect_to monthly_period_path(@transaction.date.strftime("%Y-%m"))
    else
      if (period = return_to_period)
        @period = period
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
      period = return_to_period
      redirect_to period ? monthly_period_path(period) : root_path
    else
      @categories = Category.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction = Transaction.find(params[:id])
    ActivityLogger.log(current_user, :transaction_destroyed, @transaction)
    @transaction.destroy

    if (period = return_to_period)
      redirect_to monthly_period_path(period)
    elsif params[:return_to].to_s.match?(RETURN_TO_MONTH)
      redirect_to monthly_periods_path
    else
      redirect_to root_path
    end
  end

  private

  def return_to_period
    return unless params[:return_to].to_s.match(RETURN_TO_MONTH)
    MonthlyPeriod.find_by(year: $1, month: $2)
  end

  def transaction_params
    params.expect(transaction: [ :amount, :date, :description, :category_id ])
  end
end
