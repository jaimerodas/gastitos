class MonthlyPeriodsController < ApplicationController
  before_action :require_login
  before_action :require_editor, only: [ :edit, :update ]

  def index
    @periods = MonthlyPeriod.chronological
  end

  def show
    @period = MonthlyPeriod.find_by_slug!(params[:id])
    load_show_data
    @transaction = Transaction.new(date: default_date_for_period(@period))
    @categories = Category.order(:name)
  end

  def edit
    @period = MonthlyPeriod.find_by_slug!(params[:id])
  end

  def update
    @period = MonthlyPeriod.find_by_slug!(params[:id])

    if @period.update(period_params)
      redirect_to monthly_period_path(@period)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def load_show_data
    @transactions = @period.transactions.recent.includes(:category, :created_by)
    @income_by_category = @period.income_by_category
    @expenses_by_category = @period.expenses_by_category
  end

  def default_date_for_period(period)
    if period.year == Date.current.year && period.month == Date.current.month
      Date.current
    else
      Date.new(period.year, period.month, 1)
    end
  end

  def period_params
    params.expect(monthly_period: [ :starting_balance ])
  end
end
