class CreateUtilityProviderBalanceSheets < ActiveRecord::Migration[8.1]
  def change
    create_table :utility_provider_balance_sheets do |t|
      t.references :utility_provider, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.date :month, null: false
      t.date :due_date, null: false
      t.decimal :owed, precision: 10, scale: 2, default: 0.0, null: false
      t.decimal :paid, precision: 10, scale: 2, default: 0.0, null: false

      t.timestamps
    end

    add_index :utility_provider_balance_sheets, [:utility_provider_id, :month], unique: true
    add_index :utility_provider_balance_sheets, :month
  end
end
