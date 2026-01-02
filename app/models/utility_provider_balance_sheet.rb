class UtilityProviderBalanceSheet < ApplicationRecord
  belongs_to :utility_provider
  belongs_to :property

  validates :month, presence: true
  validates :due_date, presence: true
  validates :owed, presence: true, numericality: true
  validates :paid, presence: true, numericality: true
  validates :utility_provider_id, uniqueness: {scope: :month}

  def balance
    owed - paid
  end
end
