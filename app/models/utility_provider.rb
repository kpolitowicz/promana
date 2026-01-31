class UtilityProvider < ApplicationRecord
  belongs_to :property
  has_many :utility_provider_utility_types, dependent: :destroy
  has_many :utility_types, through: :utility_provider_utility_types
  has_many :forecasts, dependent: :destroy
  has_many :utility_payments, dependent: :destroy
  has_many :utility_provider_balance_sheets, dependent: :destroy

  enum :forecast_behavior, {zero_after_expiry: "zero_after_expiry", carry_forward: "carry_forward"}

  validates :name, presence: true
  validates :forecast_behavior, presence: true
  validates :name, uniqueness: {scope: :property_id}

  def carry_forward?
    forecast_behavior == "carry_forward"
  end

  # Latest owed: next month's row if set, else current month's row if set, else nil.
  # Used on property show to surface "Next payment" for utility companies.
  def next_payment_owed
    current_begin = Date.current.beginning_of_month
    next_month_begin = current_begin + 1.month

    utility_provider_balance_sheets
      .where(month: [current_begin, next_month_begin])
      .order(month: :desc) # next month first, then current
      .first&.owed
  end
end
