class TenantPayment < ApplicationRecord
  belongs_to :property_tenant
  belongs_to :property

  validates :amount, presence: true, numericality: true
  validates :paid_date, presence: true

  def tenant
    property_tenant.tenant
  end
end
