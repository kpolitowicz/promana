class ForecastLineItem < ApplicationRecord
  belongs_to :forecast

  validates :name, presence: true
  validates :amount, presence: true, numericality: {greater_than_or_equal_to: 0, allow_blank: true}
  validates :due_date, presence: true
end
