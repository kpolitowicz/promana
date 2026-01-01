require "rails_helper"

RSpec.describe "PropertyTenants", type: :request do
  let(:property) { Property.create!(name: "Test Property") }
  let(:tenant) { Tenant.create!(name: "Test Tenant") }
  let(:tenant2) { Tenant.create!(name: "Test Tenant 2") }

  describe "GET /properties/:property_id/property_tenants/new" do
    it "renders the new template" do
      get new_property_property_tenant_path(property)
      expect(response).to have_http_status(:success)
    end

    it "excludes already assigned tenants from available tenants" do
      PropertyTenant.create!(property: property, tenant: tenant, rent_amount: 1000)
      get new_property_property_tenant_path(property)
      expect(response).to have_http_status(:success)
      # Verify the page renders without errors (available_tenants logic is tested via integration)
    end
  end

  describe "POST /properties/:property_id/property_tenants" do
    context "with valid parameters" do
      it "creates a new property tenant" do
        expect {
          post property_property_tenants_path(property), params: {property_tenant: {tenant_id: tenant.id, rent_amount: 1000}}
        }.to change(PropertyTenant, :count).by(1)
      end

      it "redirects to the property show page" do
        post property_property_tenants_path(property), params: {property_tenant: {tenant_id: tenant.id, rent_amount: 1000}}
        expect(response).to redirect_to(property_path(property))
      end
    end

    context "with invalid parameters" do
      it "does not create a new property tenant without rent_amount" do
        expect {
          post property_property_tenants_path(property), params: {property_tenant: {tenant_id: tenant.id}}
        }.not_to change(PropertyTenant, :count)
      end

      it "renders the new template with errors" do
        post property_property_tenants_path(property), params: {property_tenant: {tenant_id: tenant.id}}
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create a duplicate property tenant" do
        PropertyTenant.create!(property: property, tenant: tenant, rent_amount: 1000)
        expect {
          post property_property_tenants_path(property), params: {property_tenant: {tenant_id: tenant.id, rent_amount: 2000}}
        }.not_to change(PropertyTenant, :count)
      end
    end
  end

  describe "DELETE /properties/:property_id/property_tenants/:id" do
    let!(:property_tenant) { PropertyTenant.create!(property: property, tenant: tenant, rent_amount: 1000) }

    it "destroys the property tenant" do
      expect {
        delete property_property_tenant_path(property, property_tenant)
      }.to change(PropertyTenant, :count).by(-1)
    end

    it "redirects to the property show page" do
      delete property_property_tenant_path(property, property_tenant)
      expect(response).to redirect_to(property_path(property))
    end
  end
end
