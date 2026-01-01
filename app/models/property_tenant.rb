class PropertyTenant < ApplicationRecord
  belongs_to :property
  belongs_to :tenant

  validates :rent_amount, presence: true, numericality: {greater_than: 0}
  validates :property_id, uniqueness: {scope: :tenant_id}
end
