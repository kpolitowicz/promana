# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_02_010736) do
  create_table "forecast_line_items", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "due_date", null: false
    t.integer "forecast_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["forecast_id"], name: "index_forecast_line_items_on_forecast_id"
  end

  create_table "forecasts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "issued_date", null: false
    t.integer "property_id", null: false
    t.datetime "updated_at", null: false
    t.integer "utility_provider_id", null: false
    t.index ["property_id"], name: "index_forecasts_on_property_id"
    t.index ["utility_provider_id"], name: "index_forecasts_on_utility_provider_id"
  end

  create_table "payslip_line_items", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "payslip_id", null: false
    t.datetime "updated_at", null: false
    t.index ["payslip_id"], name: "index_payslip_line_items_on_payslip_id"
  end

  create_table "payslips", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "due_date"
    t.date "month"
    t.integer "property_id", null: false
    t.integer "property_tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_payslips_on_property_id"
    t.index ["property_tenant_id"], name: "index_payslips_on_property_tenant_id"
  end

  create_table "properties", force: :cascade do |t|
    t.text "address"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "property_tenants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "property_id", null: false
    t.decimal "rent_amount", precision: 10, scale: 2, null: false
    t.integer "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id", "tenant_id"], name: "index_property_tenants_on_property_id_and_tenant_id", unique: true
    t.index ["property_id"], name: "index_property_tenants_on_property_id"
    t.index ["tenant_id"], name: "index_property_tenants_on_tenant_id"
  end

  create_table "tenant_payments", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "month", null: false
    t.date "paid_date", null: false
    t.integer "property_id", null: false
    t.integer "property_tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_tenant_payments_on_property_id"
    t.index ["property_tenant_id", "month"], name: "index_tenant_payments_on_property_tenant_id_and_month", unique: true
    t.index ["property_tenant_id"], name: "index_tenant_payments_on_property_tenant_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "phone"
    t.datetime "updated_at", null: false
  end

  create_table "utility_payments", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "month", null: false
    t.date "paid_date", null: false
    t.integer "property_id", null: false
    t.datetime "updated_at", null: false
    t.integer "utility_provider_id", null: false
    t.index ["property_id"], name: "index_utility_payments_on_property_id"
    t.index ["utility_provider_id", "month"], name: "index_utility_payments_on_utility_provider_id_and_month", unique: true
    t.index ["utility_provider_id"], name: "index_utility_payments_on_utility_provider_id"
  end

  create_table "utility_provider_utility_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "utility_provider_id", null: false
    t.integer "utility_type_id", null: false
    t.index ["utility_provider_id", "utility_type_id"], name: "index_utility_provider_utility_types_unique", unique: true
    t.index ["utility_provider_id"], name: "index_utility_provider_utility_types_on_utility_provider_id"
    t.index ["utility_type_id"], name: "index_utility_provider_utility_types_on_utility_type_id"
  end

  create_table "utility_providers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "forecast_behavior", null: false
    t.string "name", null: false
    t.integer "property_id", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id", "name"], name: "index_utility_providers_on_property_id_and_name", unique: true
    t.index ["property_id"], name: "index_utility_providers_on_property_id"
  end

  create_table "utility_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_utility_types_on_name", unique: true
  end

  add_foreign_key "forecast_line_items", "forecasts"
  add_foreign_key "forecasts", "properties"
  add_foreign_key "forecasts", "utility_providers"
  add_foreign_key "payslip_line_items", "payslips"
  add_foreign_key "payslips", "properties"
  add_foreign_key "payslips", "property_tenants"
  add_foreign_key "property_tenants", "properties"
  add_foreign_key "property_tenants", "tenants"
  add_foreign_key "tenant_payments", "properties"
  add_foreign_key "tenant_payments", "property_tenants"
  add_foreign_key "utility_payments", "properties"
  add_foreign_key "utility_payments", "utility_providers"
  add_foreign_key "utility_provider_utility_types", "utility_providers"
  add_foreign_key "utility_provider_utility_types", "utility_types"
  add_foreign_key "utility_providers", "properties"
end
