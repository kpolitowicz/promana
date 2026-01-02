class PayslipLineItem < ApplicationRecord
  belongs_to :payslip

  validates :name, presence: true
  validates :amount, presence: true, numericality: true
end
