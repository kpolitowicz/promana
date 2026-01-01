class CreateForecasts < ActiveRecord::Migration[8.1]
  def change
    create_table :forecasts do |t|
      t.references :utility_provider, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.date :issued_date, null: false

      t.timestamps
    end
  end
end
