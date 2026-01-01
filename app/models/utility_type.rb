class UtilityType < ApplicationRecord
  has_many :utility_provider_utility_types, dependent: :destroy
  has_many :utility_providers, through: :utility_provider_utility_types

  validates :name, presence: true, uniqueness: true
end
