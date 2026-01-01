require "rails_helper"

RSpec.describe PropertyTenant, type: :model do
  describe "associations" do
    it "belongs to property" do
      property_tenant = PropertyTenant.reflect_on_association(:property)
      expect(property_tenant).not_to be_nil
      expect(property_tenant.macro).to eq(:belongs_to)
    end

    it "belongs to tenant" do
      property_tenant = PropertyTenant.reflect_on_association(:tenant)
      expect(property_tenant).not_to be_nil
      expect(property_tenant.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    let(:property) { Property.create!(name: "Test Property") }
    let(:tenant) { Tenant.create!(name: "Test Tenant") }

    it "requires rent_amount" do
      property_tenant = PropertyTenant.new(property: property, tenant: tenant)
      expect(property_tenant).not_to be_valid
      expect(property_tenant.errors[:rent_amount]).to include("can't be blank")
    end

    it "requires rent_amount to be greater than 0" do
      property_tenant = PropertyTenant.new(property: property, tenant: tenant, rent_amount: 0)
      expect(property_tenant).not_to be_valid
      expect(property_tenant.errors[:rent_amount]).to be_present
    end

    it "requires rent_amount to be greater than 0 (negative)" do
      property_tenant = PropertyTenant.new(property: property, tenant: tenant, rent_amount: -100)
      expect(property_tenant).not_to be_valid
      expect(property_tenant.errors[:rent_amount]).to be_present
    end

    it "validates uniqueness of property_id scoped to tenant_id" do
      PropertyTenant.create!(property: property, tenant: tenant, rent_amount: 1000)
      duplicate = PropertyTenant.new(property: property, tenant: tenant, rent_amount: 2000)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:property_id]).to be_present
    end

    it "allows same tenant for different properties" do
      property2 = Property.create!(name: "Test Property 2")
      PropertyTenant.create!(property: property, tenant: tenant, rent_amount: 1000)
      duplicate = PropertyTenant.new(property: property2, tenant: tenant, rent_amount: 2000)
      expect(duplicate).to be_valid
    end

    it "allows same property for different tenants" do
      tenant2 = Tenant.create!(name: "Test Tenant 2")
      PropertyTenant.create!(property: property, tenant: tenant, rent_amount: 1000)
      duplicate = PropertyTenant.new(property: property, tenant: tenant2, rent_amount: 2000)
      expect(duplicate).to be_valid
    end
  end
end
