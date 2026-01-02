class ForecastLineItem < ApplicationRecord
  belongs_to :forecast

  validates :name, presence: true
  validates :amount, presence: true, numericality: true
  validates :due_date, presence: true
end
