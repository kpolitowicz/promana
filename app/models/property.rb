class Property < ApplicationRecord
  has_many :property_tenants, dependent: :destroy
  has_many :tenants, through: :property_tenants

  validates :name, presence: true
end
