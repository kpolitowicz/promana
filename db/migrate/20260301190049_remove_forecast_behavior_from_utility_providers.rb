class RemoveForecastBehaviorFromUtilityProviders < ActiveRecord::Migration[8.1]
  def change
    remove_column :utility_providers, :forecast_behavior, :string
  end
end
