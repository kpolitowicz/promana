class CreatePayslips < ActiveRecord::Migration[8.1]
  def change
    create_table :payslips do |t|
      t.references :property, null: false, foreign_key: true
      t.references :property_tenant, null: false, foreign_key: true
      t.date :month
      t.date :due_date

      t.timestamps
    end
  end
end
