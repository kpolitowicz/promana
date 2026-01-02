class RemoveMonthFromUtilityPayments < ActiveRecord::Migration[8.1]
  def change
    remove_index :utility_payments, [:utility_provider_id, :month], if_exists: true
    remove_column :utility_payments, :month, :date
  end
end
