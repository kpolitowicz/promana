require "rails_helper"

RSpec.describe TenantPayment, type: :model do
  let(:property) { Property.create!(name: "Test Property") }
  let(:tenant) { Tenant.create!(name: "Test Tenant") }
  let(:property_tenant) { PropertyTenant.create!(property: property, tenant: tenant, rent_amount: 1000.00) }

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
    it "is valid with month, amount, and paid_date" do
      payment = TenantPayment.new(property_tenant: property_tenant, property: property, month: Date.today, amount: 1000.00, paid_date: Date.today)
      expect(payment).to be_valid
    end

    it "requires month" do
      payment = TenantPayment.new(property_tenant: property_tenant, property: property, amount: 1000.00, paid_date: Date.today)
      expect(payment).not_to be_valid
      expect(payment.errors[:month]).to include("can't be blank")
    end

    it "requires amount" do
      payment = TenantPayment.new(property_tenant: property_tenant, property: property, month: Date.today, paid_date: Date.today)
      expect(payment).not_to be_valid
      expect(payment.errors[:amount]).to include("can't be blank")
    end

    it "requires paid_date" do
      payment = TenantPayment.new(property_tenant: property_tenant, property: property, month: Date.today, amount: 1000.00)
      expect(payment).not_to be_valid
      expect(payment.errors[:paid_date]).to include("can't be blank")
    end

    it "requires unique property_tenant and month combination" do
      TenantPayment.create!(property_tenant: property_tenant, property: property, month: Date.today.beginning_of_month, amount: 1000.00, paid_date: Date.today)
      duplicate = TenantPayment.new(property_tenant: property_tenant, property: property, month: Date.today.beginning_of_month, amount: 2000.00, paid_date: Date.today)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:property_id]).to include("has already been taken")
    end
  end

  describe "#tenant" do
    it "returns the tenant through property_tenant" do
      payment = TenantPayment.create!(property_tenant: property_tenant, property: property, month: Date.today, amount: 1000.00, paid_date: Date.today)
      expect(payment.tenant).to eq(tenant)
    end
  end
end
