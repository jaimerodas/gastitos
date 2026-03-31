namespace :monthly_periods do
  desc "Create MonthlyPeriod records for all existing transactions"
  task backfill: :environment do
    Transaction.pluck(:date)
               .map { |d| [ d.month, d.year ] }
               .uniq
               .sort_by { |m, y| [ y, m ] }
               .each do |month, year|
      MonthlyPeriod.find_or_create_for_date(Date.new(year, month, 1))
    end

    puts "Created #{MonthlyPeriod.count} monthly period(s)"
  end
end
