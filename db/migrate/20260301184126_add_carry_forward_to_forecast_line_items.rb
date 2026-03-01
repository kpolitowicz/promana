class AddCarryForwardToForecastLineItems < ActiveRecord::Migration[8.1]
  def change
    add_column :forecast_line_items, :carry_forward, :boolean, default: false, null: false
  end
end
