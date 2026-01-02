require "rails_helper"

RSpec.describe "Payslips", type: :request do
  let(:property) { Property.create!(name: "Test Property") }
  let(:tenant) { Tenant.create!(name: "Test Tenant") }
  let(:property_tenant) { PropertyTenant.create!(property: property, tenant: tenant, rent_amount: 1000.00) }

  describe "GET /properties/:property_id/property_tenants/:property_tenant_id/payslips" do
    it "returns http success" do
      get property_property_tenant_payslips_path(property, property_tenant)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /properties/:property_id/property_tenants/:property_tenant_id/payslips/new" do
    it "returns http success" do
      get new_property_property_tenant_payslip_path(property, property_tenant)
      expect(response).to have_http_status(:success)
    end

    it "generates payslip with default next month" do
      get new_property_property_tenant_payslip_path(property, property_tenant)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(Date.today.next_month.beginning_of_month.strftime("%Y-%m-%d"))
    end

    it "allows overriding month via params" do
      custom_month = Date.today + 2.months
      get new_property_property_tenant_payslip_path(property, property_tenant, month: custom_month)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(custom_month.strftime("%Y-%m-%d"))
    end

    it "allows overriding due_date via params" do
      custom_due_date = Date.today + 20.days
      get new_property_property_tenant_payslip_path(property, property_tenant, due_date: custom_due_date)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(custom_due_date.strftime("%Y-%m-%d"))
    end
  end

  describe "POST /properties/:property_id/property_tenants/:property_tenant_id/payslips" do
    let(:month) { (Date.today + 3.months).beginning_of_month } # Use a month far in the future to avoid conflicts
    let(:due_date) { Date.new(month.year, month.month, 10) }
    let(:line_items) do
      [
        {name: "Rent", amount: "1000.00"},
        {name: "Utilities", amount: "250.50"}
      ]
    end

    it "creates a new payslip with line items" do
      expect {
        post property_property_tenant_payslips_path(property, property_tenant), params: {
          payslip: {month: month.to_s, due_date: due_date.to_s},
          line_items: line_items
        }
      }.to change(Payslip, :count).by(1)
        .and change(PayslipLineItem, :count).by(2)

      expect(response).to have_http_status(:redirect)
      payslip = Payslip.last
      expect(payslip.month).to eq(month)
      expect(payslip.due_date).to eq(due_date)
      expect(payslip.payslip_line_items.count).to eq(2)
    end

    it "redirects to the payslip show page" do
      post property_property_tenant_payslips_path(property, property_tenant), params: {
        payslip: {month: month.to_s, due_date: due_date.to_s},
        line_items: line_items
      }
      payslip = Payslip.last
      expect(payslip).not_to be_nil
      expect(response).to redirect_to(property_property_tenant_payslip_path(property, property_tenant, payslip))
    end

    it "does not create payslip if month is missing" do
      expect {
        post property_property_tenant_payslips_path(property, property_tenant), params: {
          payslip: {due_date: due_date},
          line_items: line_items
        }
      }.not_to change(Payslip, :count)
    end
  end

  describe "GET /properties/:property_id/property_tenants/:property_tenant_id/payslips/:id" do
    let(:payslip) { Payslip.create!(property: property, property_tenant: property_tenant, month: Date.today, due_date: Date.today + 10.days) }

    before do
      payslip.payslip_line_items.create!(name: "Rent", amount: 1000.00)
      payslip.payslip_line_items.create!(name: "Utilities", amount: 250.50)
    end

    it "returns http success" do
      get property_property_tenant_payslip_path(property, property_tenant, payslip)
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /properties/:property_id/property_tenants/:property_tenant_id/payslips/:id" do
    let!(:payslip) { Payslip.create!(property: property, property_tenant: property_tenant, month: Date.today, due_date: Date.today + 10.days) }

    before do
      payslip.payslip_line_items.create!(name: "Rent", amount: 1000.00)
    end

    it "deletes the payslip and its line items" do
      expect {
        delete property_property_tenant_payslip_path(property, property_tenant, payslip)
      }.to change(Payslip, :count).by(-1)
        .and change(PayslipLineItem, :count).by(-1)

      expect(response).to redirect_to(property_property_tenant_payslips_path(property, property_tenant))
    end
  end
end
