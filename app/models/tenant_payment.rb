class TenantPayment < ApplicationRecord
  belongs_to :property_tenant
  belongs_to :property

  validates :month, presence: true
  validates :amount, presence: true, numericality: true
  validates :paid_date, presence: true
  validates :property_id, uniqueness: {scope: [:property_tenant_id, :month]}

  def tenant
    property_tenant.tenant
  end
end
