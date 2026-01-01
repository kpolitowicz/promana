class UtilityProviderUtilityType < ApplicationRecord
  belongs_to :utility_provider
  belongs_to :utility_type

  validates :utility_provider_id, uniqueness: {scope: :utility_type_id}
end
