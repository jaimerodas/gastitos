class MonthlyPeriodsController < ApplicationController
  before_action :require_login

  def index
    @periods = MonthlyPeriod.chronological
  end

  def show
    @period = MonthlyPeriod.find(params[:id])
    @transactions = @period.transactions.recent.includes(:category, :created_by)
    @income_by_category = @period.income_by_category
    @expenses_by_category = @period.expenses_by_category
  end

  def edit
    @period = MonthlyPeriod.find(params[:id])
  end

  def update
    @period = MonthlyPeriod.find(params[:id])

    if @period.update(period_params)
      redirect_to monthly_period_path(@period)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def period_params
    params.expect(monthly_period: [ :starting_balance ])
  end
end
