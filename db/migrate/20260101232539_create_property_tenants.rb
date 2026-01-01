class CreatePropertyTenants < ActiveRecord::Migration[8.1]
  def change
    create_table :property_tenants do |t|
      t.references :property, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.decimal :rent_amount, precision: 10, scale: 2, null: false

      t.index [:property_id, :tenant_id], unique: true

      t.timestamps
    end
  end
end
