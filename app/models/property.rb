class Property < ApplicationRecord
  has_many :property_tenants, dependent: :destroy
  has_many :tenants, through: :property_tenants
  has_many :utility_providers, dependent: :destroy

  validates :name, presence: true
end
