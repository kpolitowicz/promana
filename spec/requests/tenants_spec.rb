require "rails_helper"

RSpec.describe "Tenants", type: :request do
  describe "GET /tenants" do
    it "returns a successful response" do
      get tenants_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /tenants/new" do
    it "returns a successful response" do
      get new_tenant_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /tenants" do
    context "with valid parameters" do
      it "creates a new tenant" do
        expect {
          post tenants_path, params: {tenant: {name: "Test Tenant", email: "test@example.com", phone: "123-456-7890"}}
        }.to change(Tenant, :count).by(1)
      end

      it "redirects to the created tenant" do
        post tenants_path, params: {tenant: {name: "Test Tenant", email: "test@example.com", phone: "123-456-7890"}}
        expect(response).to redirect_to(tenant_path(Tenant.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new tenant" do
        expect {
          post tenants_path, params: {tenant: {name: ""}}
        }.not_to change(Tenant, :count)
      end

      it "renders the new template" do
        post tenants_path, params: {tenant: {name: ""}}
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /tenants/:id" do
    let(:tenant) { Tenant.create!(name: "Test Tenant", email: "test@example.com") }

    it "returns a successful response" do
      get tenant_path(tenant)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /tenants/:id/edit" do
    let(:tenant) { Tenant.create!(name: "Test Tenant", email: "test@example.com") }

    it "returns a successful response" do
      get edit_tenant_path(tenant)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /tenants/:id" do
    let(:tenant) { Tenant.create!(name: "Test Tenant", email: "test@example.com") }

    context "with valid parameters" do
      it "updates the tenant" do
        patch tenant_path(tenant), params: {tenant: {name: "Updated Tenant"}}
        tenant.reload
        expect(tenant.name).to eq("Updated Tenant")
      end

      it "redirects to the tenant" do
        patch tenant_path(tenant), params: {tenant: {name: "Updated Tenant"}}
        expect(response).to redirect_to(tenant_path(tenant))
      end
    end

    context "with invalid parameters" do
      it "does not update the tenant" do
        patch tenant_path(tenant), params: {tenant: {name: ""}}
        tenant.reload
        expect(tenant.name).to eq("Test Tenant")
      end

      it "renders the edit template" do
        patch tenant_path(tenant), params: {tenant: {name: ""}}
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /tenants/:id" do
    let!(:tenant) { Tenant.create!(name: "Test Tenant", email: "test@example.com") }

    it "destroys the tenant" do
      expect {
        delete tenant_path(tenant)
      }.to change(Tenant, :count).by(-1)
    end

    it "redirects to the tenants list" do
      delete tenant_path(tenant)
      expect(response).to redirect_to(tenants_path)
    end
  end
end
