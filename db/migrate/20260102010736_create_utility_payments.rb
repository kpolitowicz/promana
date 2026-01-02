class CreateUtilityPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :utility_payments do |t|
      t.references :utility_provider, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.date :month, null: false
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.date :paid_date, null: false

      t.timestamps
    end

    add_index :utility_payments, [:utility_provider_id, :month], unique: true
  end
end
