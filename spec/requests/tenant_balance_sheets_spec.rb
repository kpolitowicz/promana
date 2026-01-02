require "rails_helper"

RSpec.describe "TenantBalanceSheets", type: :request do
  fixtures :properties, :tenants, :property_tenants

  let(:property) { properties(:property_one) }
  let(:property_tenant) { property_tenants(:property_tenant_one) }

  describe "GET /properties/:property_id/property_tenants/:property_tenant_id/tenant_balance_sheets" do
    it "returns http success" do
      get property_property_tenant_tenant_balance_sheets_path(property, property_tenant)
      expect(response).to have_http_status(:success)
    end

    it "displays balance sheets ordered by due_date descending" do
      TenantBalanceSheet.create!(
        property_tenant: property_tenant,
        property: property,
        month: Date.new(2026, 1, 1),
        due_date: Date.new(2026, 1, 10),
        owed: 1000.00,
        paid: 1000.00
      )
      TenantBalanceSheet.create!(
        property_tenant: property_tenant,
        property: property,
        month: Date.new(2026, 2, 1),
        due_date: Date.new(2026, 2, 15),
        owed: 1200.00,
        paid: 1200.00
      )

      get property_property_tenant_tenant_balance_sheets_path(property, property_tenant)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("February 2026")
      expect(response.body).to include("January 2026")
    end

    it "displays current balance" do
      TenantBalanceSheet.create!(
        property_tenant: property_tenant,
        property: property,
        month: Date.new(2026, 1, 1),
        due_date: Date.new(2026, 1, 10),
        owed: 1000.00,
        paid: 800.00
      )

      get property_property_tenant_tenant_balance_sheets_path(property, property_tenant)
      expect(response.body).to include("200.00")
    end
  end

  describe "PATCH /properties/:property_id/property_tenants/:property_tenant_id/tenant_balance_sheets/update_all" do
    it "updates balance sheets and redirects" do
      month = Date.today.beginning_of_month
      payslip = Payslip.create!(
        property: property,
        property_tenant: property_tenant,
        month: month,
        due_date: Date.new(month.year, month.month, 10)
      )
      payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 1000.00)

      patch update_all_property_property_tenant_tenant_balance_sheets_path(property, property_tenant)
      expect(response).to redirect_to(property_property_tenant_tenant_balance_sheets_path(property, property_tenant))
      expect(TenantBalanceSheet.where(property_tenant: property_tenant).count).to eq(1)
    end
  end
end
