class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :date, null: false
      t.string :description
      t.references :category, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
