require "rails_helper"

RSpec.describe TenantBalanceSheet, type: :model do
  fixtures :properties, :tenants, :property_tenants

  let(:property) { properties(:property_one) }
  let(:property_tenant) { property_tenants(:property_tenant_one) }

  describe "associations" do
    it "belongs to property_tenant" do
      association = TenantBalanceSheet.reflect_on_association(:property_tenant)
      expect(association).not_to be_nil
      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to property" do
      association = TenantBalanceSheet.reflect_on_association(:property)
      expect(association).not_to be_nil
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "is valid with month, due_date, owed, and paid" do
      balance_sheet = TenantBalanceSheet.new(
        property_tenant: property_tenant,
        property: property,
        month: Date.today.beginning_of_month,
        due_date: Date.today,
        owed: 1000.00,
        paid: 1000.00
      )
      expect(balance_sheet).to be_valid
    end

    it "requires month" do
      balance_sheet = TenantBalanceSheet.new(
        property_tenant: property_tenant,
        property: property,
        due_date: Date.today,
        owed: 1000.00,
        paid: 1000.00
      )
      expect(balance_sheet).not_to be_valid
      expect(balance_sheet.errors[:month]).to include("can't be blank")
    end

    it "requires due_date" do
      balance_sheet = TenantBalanceSheet.new(
        property_tenant: property_tenant,
        property: property,
        month: Date.today.beginning_of_month,
        owed: 1000.00,
        paid: 1000.00
      )
      expect(balance_sheet).not_to be_valid
      expect(balance_sheet.errors[:due_date]).to include("can't be blank")
    end

    it "validates uniqueness of property_tenant_id scoped to month" do
      TenantBalanceSheet.create!(
        property_tenant: property_tenant,
        property: property,
        month: Date.today.beginning_of_month,
        due_date: Date.today,
        owed: 1000.00,
        paid: 1000.00
      )
      duplicate = TenantBalanceSheet.new(
        property_tenant: property_tenant,
        property: property,
        month: Date.today.beginning_of_month,
        due_date: Date.today + 1.day,
        owed: 2000.00,
        paid: 2000.00
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:property_tenant_id]).to be_present
    end
  end

  describe "#balance" do
    it "calculates balance as owed minus paid" do
      balance_sheet = TenantBalanceSheet.create!(
        property_tenant: property_tenant,
        property: property,
        month: Date.today.beginning_of_month,
        due_date: Date.today,
        owed: 1000.00,
        paid: 800.00
      )
      expect(balance_sheet.balance).to eq(200.00)
    end

    it "returns negative balance when paid exceeds owed" do
      balance_sheet = TenantBalanceSheet.create!(
        property_tenant: property_tenant,
        property: property,
        month: Date.today.beginning_of_month,
        due_date: Date.today,
        owed: 1000.00,
        paid: 1200.00
      )
      expect(balance_sheet.balance).to eq(-200.00)
    end

    it "returns zero when paid equals owed" do
      balance_sheet = TenantBalanceSheet.create!(
        property_tenant: property_tenant,
        property: property,
        month: Date.today.beginning_of_month,
        due_date: Date.today,
        owed: 1000.00,
        paid: 1000.00
      )
      expect(balance_sheet.balance).to eq(0.00)
    end
  end
end
