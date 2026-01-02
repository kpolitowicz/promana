require "rails_helper"

RSpec.describe "TenantPayments", type: :request do
  let(:property) { Property.create!(name: "Test Property") }
  let(:tenant) { Tenant.create!(name: "Test Tenant") }
  let(:property_tenant) { PropertyTenant.create!(property: property, tenant: tenant, rent_amount: 1000.00) }

  describe "GET /properties/:property_id/property_tenants/:property_tenant_id/tenant_payments" do
    it "returns http success" do
      get property_property_tenant_tenant_payments_path(property, property_tenant)
      expect(response).to have_http_status(:success)
    end

    it "displays all tenant payments" do
      payment1 = TenantPayment.create!(property_tenant: property_tenant, property: property, month: Date.today.beginning_of_month, amount: 1000.00, paid_date: Date.today)
      payment2 = TenantPayment.create!(property_tenant: property_tenant, property: property, month: (Date.today - 1.month).beginning_of_month, amount: 1200.00, paid_date: Date.today - 10.days)

      get property_property_tenant_tenant_payments_path(property, property_tenant)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("1000.00")
      expect(response.body).to include("1200.00")
    end
  end

  describe "GET /properties/:property_id/property_tenants/:property_tenant_id/tenant_payments/new" do
    it "returns http success" do
      get new_property_property_tenant_tenant_payment_path(property, property_tenant)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /properties/:property_id/property_tenants/:property_tenant_id/tenant_payments" do
    let(:month) { (Date.today + 3.months).beginning_of_month }
    let(:paid_date) { Date.today }
    let(:amount) { 1000.00 }

    it "creates a new tenant payment" do
      expect {
        post property_property_tenant_tenant_payments_path(property, property_tenant), params: {
          tenant_payment: {
            month: month,
            amount: amount,
            paid_date: paid_date
          }
        }
      }.to change(TenantPayment, :count).by(1)
    end

    it "redirects to the payment show page" do
      post property_property_tenant_tenant_payments_path(property, property_tenant), params: {
        tenant_payment: {
          month: month,
          amount: amount,
          paid_date: paid_date
        }
      }
      payment = TenantPayment.last
      expect(response).to redirect_to(property_property_tenant_tenant_payment_path(property, property_tenant, payment))
    end

    it "sets the property and property_tenant associations" do
      post property_property_tenant_tenant_payments_path(property, property_tenant), params: {
        tenant_payment: {
          month: month,
          amount: amount,
          paid_date: paid_date
        }
      }
      payment = TenantPayment.last
      expect(payment.property).to eq(property)
      expect(payment.property_tenant).to eq(property_tenant)
    end

    context "with invalid parameters" do
      it "does not create with empty month" do
        expect {
          post property_property_tenant_tenant_payments_path(property, property_tenant), params: {
            tenant_payment: {
              month: "",
              amount: amount,
              paid_date: paid_date
            }
          }
        }.not_to change(TenantPayment, :count)
      end

      it "renders the new template with errors" do
        post property_property_tenant_tenant_payments_path(property, property_tenant), params: {
          tenant_payment: {
            month: "",
            amount: amount,
            paid_date: paid_date
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /properties/:property_id/property_tenants/:property_tenant_id/tenant_payments/:id" do
    let(:payment) do
      TenantPayment.create!(
        property_tenant: property_tenant,
        property: property,
        month: Date.today.beginning_of_month,
        amount: 1000.00,
        paid_date: Date.today
      )
    end

    it "returns http success" do
      get property_property_tenant_tenant_payment_path(property, property_tenant, payment)
      expect(response).to have_http_status(:success)
    end

    it "displays the payment details" do
      get property_property_tenant_tenant_payment_path(property, property_tenant, payment)
      expect(response.body).to include("1000.00")
      expect(response.body).to include(payment.month.strftime("%B %Y"))
    end
  end

  describe "GET /properties/:property_id/property_tenants/:property_tenant_id/tenant_payments/:id/edit" do
    let(:payment) do
      TenantPayment.create!(
        property_tenant: property_tenant,
        property: property,
        month: Date.today.beginning_of_month,
        amount: 1000.00,
        paid_date: Date.today
      )
    end

    it "returns http success" do
      get edit_property_property_tenant_tenant_payment_path(property, property_tenant, payment)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /properties/:property_id/property_tenants/:property_tenant_id/tenant_payments/:id" do
    let(:payment) do
      TenantPayment.create!(
        property_tenant: property_tenant,
        property: property,
        month: Date.today.beginning_of_month,
        amount: 1000.00,
        paid_date: Date.today
      )
    end

    it "updates the payment" do
      patch property_property_tenant_tenant_payment_path(property, property_tenant, payment), params: {
        tenant_payment: {
          amount: 1200.00
        }
      }
      payment.reload
      expect(payment.amount).to eq(1200.00)
    end

    it "redirects to the payment show page" do
      patch property_property_tenant_tenant_payment_path(property, property_tenant, payment), params: {
        tenant_payment: {
          amount: 1200.00
        }
      }
      expect(response).to redirect_to(property_property_tenant_tenant_payment_path(property, property_tenant, payment))
    end

    context "with invalid parameters" do
      it "does not update with empty amount" do
        original_amount = payment.amount
        patch property_property_tenant_tenant_payment_path(property, property_tenant, payment), params: {
          tenant_payment: {
            amount: ""
          }
        }
        payment.reload
        expect(payment.amount).to eq(original_amount)
      end

      it "renders the edit template with errors" do
        patch property_property_tenant_tenant_payment_path(property, property_tenant, payment), params: {
          tenant_payment: {
            amount: ""
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /properties/:property_id/property_tenants/:property_tenant_id/tenant_payments/:id" do
    let!(:payment) do
      TenantPayment.create!(
        property_tenant: property_tenant,
        property: property,
        month: Date.today.beginning_of_month,
        amount: 1000.00,
        paid_date: Date.today
      )
    end

    it "destroys the payment" do
      expect {
        delete property_property_tenant_tenant_payment_path(property, property_tenant, payment)
      }.to change(TenantPayment, :count).by(-1)
    end

    it "redirects to the payments index" do
      delete property_property_tenant_tenant_payment_path(property, property_tenant, payment)
      expect(response).to redirect_to(property_property_tenant_tenant_payments_path(property, property_tenant))
    end
  end
end
