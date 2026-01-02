class UtilityPayment < ApplicationRecord
  belongs_to :utility_provider
  belongs_to :property

  validates :month, presence: true
  validates :amount, presence: true, numericality: true
  validates :paid_date, presence: true
  validates :utility_provider_id, uniqueness: {scope: [:property_id, :month]}
end
