class CreateForecastLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :forecast_line_items do |t|
      t.references :forecast, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false, default: 0
      t.date :due_date, null: false

      t.timestamps
    end
  end
end
