class CreatePayslipLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :payslip_line_items do |t|
      t.references :payslip, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false

      t.timestamps
    end
  end
end
