class UtilityPayment < ApplicationRecord
  belongs_to :utility_provider
  belongs_to :property

  validates :amount, presence: true, numericality: true
  validates :paid_date, presence: true
end
