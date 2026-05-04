class MonthlyPeriodsController < ApplicationController
  before_action :require_login
  before_action :require_editor, only: [ :edit, :update ]

  def index
    @periods = MonthlyPeriod.chronological
  end

  def show
    @period_report = MonthlyPeriodReport.new(MonthlyPeriod.find_by_slug!(params[:id]))
    @transaction = Transaction.new(date: default_date_for_period(@period_report.period))
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
