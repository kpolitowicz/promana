class TenantBalanceSheet < ApplicationRecord
  belongs_to :property_tenant
  belongs_to :property

  validates :month, presence: true
  validates :due_date, presence: true
  validates :owed, presence: true, numericality: true
  validates :paid, presence: true, numericality: true
  validates :property_tenant_id, uniqueness: {scope: :month}

  def balance
    owed - paid
  end
end
