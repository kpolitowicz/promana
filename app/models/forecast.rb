class Forecast < ApplicationRecord
  belongs_to :utility_provider
  belongs_to :property
  has_many :forecast_line_items, dependent: :destroy

  accepts_nested_attributes_for :forecast_line_items, allow_destroy: true, reject_if: :all_blank

  validates :issued_date, presence: true
end
