class CreateUtilityProviderUtilityTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :utility_provider_utility_types do |t|
      t.references :utility_provider, null: false, foreign_key: true
      t.references :utility_type, null: false, foreign_key: true

      t.timestamps
    end

    add_index :utility_provider_utility_types, [:utility_provider_id, :utility_type_id], unique: true, name: "index_utility_provider_utility_types_unique"
  end
end
