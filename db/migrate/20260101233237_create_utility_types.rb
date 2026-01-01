class CreateUtilityTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :utility_types do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :utility_types, :name, unique: true
  end
end
