class PropertyTenant < ApplicationRecord
  belongs_to :property
  belongs_to :tenant
  has_many :payslips, dependent: :destroy
  has_many :tenant_payments, dependent: :destroy
  has_many :tenant_balance_sheets, dependent: :destroy

  validates :rent_amount, presence: true, numericality: {greater_than: 0}
  validates :property_id, uniqueness: {scope: :tenant_id}
end
