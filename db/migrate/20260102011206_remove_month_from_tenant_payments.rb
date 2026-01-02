class RemoveMonthFromTenantPayments < ActiveRecord::Migration[8.1]
  def change
    remove_index :tenant_payments, [:property_tenant_id, :month], if_exists: true
    remove_column :tenant_payments, :month, :date
  end
end
