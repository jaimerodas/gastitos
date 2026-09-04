class MonthlyPeriodsController < ApplicationController
  before_action :require_login
  before_action :require_editor, only: [ :edit, :update ]

  def index
    @periods = MonthlyPeriod.chronological
  end

  def summary
    @window = MonthlyPeriodWindow.new(size: params[:meses], anchor: params[:hasta])
    @report = MultiPeriodReport.new(@window.periods)
  end

  def show
    @period = MonthlyPeriod.find_by_slug!(params[:id])
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

  def default_date_for_period(period)
    period.date_range.cover?(Date.current) ? Date.current : period.start_date
  end

  def period_params
    params.expect(monthly_period: [ :starting_balance ])
  end
end
