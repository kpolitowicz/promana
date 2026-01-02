require "rails_helper"

RSpec.describe TenantPayment, type: :model do
  fixtures :properties, :tenants, :property_tenants

  let(:property) { properties(:property_one) }
  let(:tenant) { tenants(:tenant_one) }
  let(:property_tenant) { property_tenants(:property_tenant_one) }

  describe "associations" do
    it "belongs to property_tenant" do
      association = TenantPayment.reflect_on_association(:property_tenant)
      expect(association).not_to be_nil
      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to property" do
      association = TenantPayment.reflect_on_association(:property)
      expect(association).not_to be_nil
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "is valid with amount and paid_date" do
      payment = TenantPayment.new(property_tenant: property_tenant, property: property, amount: 1000.00, paid_date: Date.today)
      expect(payment).to be_valid
    end

    it "requires amount" do
      payment = TenantPayment.new(property_tenant: property_tenant, property: property, paid_date: Date.today)
      expect(payment).not_to be_valid
      expect(payment.errors[:amount]).to include("can't be blank")
    end

    it "requires paid_date" do
      payment = TenantPayment.new(property_tenant: property_tenant, property: property, amount: 1000.00)
      expect(payment).not_to be_valid
      expect(payment.errors[:paid_date]).to include("can't be blank")
    end
  end

  describe "#tenant" do
    it "returns the tenant through property_tenant" do
      payment = TenantPayment.create!(property_tenant: property_tenant, property: property, amount: 1000.00, paid_date: Date.today)
      expect(payment.tenant).to eq(tenant)
    end
  end
end
