class Payslip < ApplicationRecord
  belongs_to :property
  belongs_to :property_tenant
  has_many :payslip_line_items, dependent: :destroy

  accepts_nested_attributes_for :payslip_line_items, allow_destroy: true

  validates :month, presence: true
  validates :due_date, presence: true
  validates :property_id, uniqueness: {scope: [:property_tenant_id, :month]}

  def total_amount
    payslip_line_items.sum(:amount)
  end

  def tenant
    property_tenant.tenant
  end
end
