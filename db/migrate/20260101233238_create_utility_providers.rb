class CreateUtilityProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :utility_providers do |t|
      t.string :name, null: false
      t.string :forecast_behavior, null: false
      t.references :property, null: false, foreign_key: true

      t.timestamps
    end

    add_index :utility_providers, [:property_id, :name], unique: true
  end
end
