class TransactionsController < ApplicationController
  before_action :require_login

  def index
    @transaction = Transaction.new(date: Date.current)
    load_index_data
  end

  def create
    @transaction = Transaction.new(transaction_params)
    @transaction.created_by = current_user

    if @transaction.save
      redirect_to root_path
    else
      load_index_data
      render :index, status: :unprocessable_entity
    end
  end

  def edit
    @transaction = Transaction.find(params[:id])
    @categories = Category.order(:name)
    @last_transaction = Transaction.recent.first
  end

  def update
    @transaction = Transaction.find(params[:id])

    if @transaction.update(transaction_params)
      redirect_to safe_return_path
    else
      @categories = Category.order(:name)
      @last_transaction = Transaction.recent.first
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction = Transaction.find(params[:id])
    month = @transaction.date.month
    year = @transaction.date.year
    @transaction.destroy

    period = MonthlyPeriod.find_by(month: month, year: year)
    redirect_to period ? monthly_period_path(period) : root_path
  end

  private

  def load_index_data
    @transactions = Transaction.recent.includes(:category, :created_by).limit(10)
    @categories = Category.order(:name)
    @last_transaction = Transaction.recent.first
  end

  def transaction_params
    params.expect(transaction: [ :amount, :date, :description, :category_id ])
  end

  def safe_return_path
    return_to = params[:return_to]
    if return_to.present? && return_to.match?(%r{\A/meses/\d+\z})
      return_to
    else
      root_path
    end
  end
end
