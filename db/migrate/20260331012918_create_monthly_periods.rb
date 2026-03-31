class CreateMonthlyPeriods < ActiveRecord::Migration[8.1]
  def change
    create_table :monthly_periods do |t|
      t.integer :month, null: false
      t.integer :year, null: false
      t.decimal :starting_balance, precision: 12, scale: 2, null: false, default: 0

      t.timestamps
    end

    add_index :monthly_periods, [ :year, :month ], unique: true
  end
end
