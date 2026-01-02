class UtilityProvider < ApplicationRecord
  belongs_to :property
  has_many :utility_provider_utility_types, dependent: :destroy
  has_many :utility_types, through: :utility_provider_utility_types
  has_many :forecasts, dependent: :destroy
  has_many :utility_payments, dependent: :destroy

  enum :forecast_behavior, {zero_after_expiry: "zero_after_expiry", carry_forward: "carry_forward"}

  validates :name, presence: true
  validates :forecast_behavior, presence: true
  validates :name, uniqueness: {scope: :property_id}
end
