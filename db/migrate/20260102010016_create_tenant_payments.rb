class CreateTenantPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :tenant_payments do |t|
      t.references :property_tenant, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.date :month, null: false
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.date :paid_date, null: false

      t.timestamps
    end

    add_index :tenant_payments, [:property_tenant_id, :month], unique: true
  end
end
