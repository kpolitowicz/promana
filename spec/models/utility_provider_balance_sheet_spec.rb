require "rails_helper"

RSpec.describe UtilityProviderBalanceSheet, type: :model do
  fixtures :properties, :utility_providers

  let(:property) { properties(:property_one) }
  let(:utility_provider) { utility_providers(:utility_provider_one) }

  describe "associations" do
    it "belongs to utility_provider" do
      association = UtilityProviderBalanceSheet.reflect_on_association(:utility_provider)
      expect(association).not_to be_nil
      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to property" do
      association = UtilityProviderBalanceSheet.reflect_on_association(:property)
      expect(association).not_to be_nil
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "is valid with month, due_date, owed, and paid" do
      balance_sheet = UtilityProviderBalanceSheet.new(
        utility_provider: utility_provider,
        property: property,
        month: Date.today.beginning_of_month,
        due_date: Date.today,
        owed: 500.00,
        paid: 500.00
      )
      expect(balance_sheet).to be_valid
    end

    it "requires month" do
      balance_sheet = UtilityProviderBalanceSheet.new(
        utility_provider: utility_provider,
        property: property,
        due_date: Date.today,
        owed: 500.00,
        paid: 500.00
      )
      expect(balance_sheet).not_to be_valid
      expect(balance_sheet.errors[:month]).to include("can't be blank")
    end

    it "validates uniqueness of utility_provider_id scoped to month" do
      UtilityProviderBalanceSheet.create!(
        utility_provider: utility_provider,
        property: property,
        month: Date.today.beginning_of_month,
        due_date: Date.today,
        owed: 500.00,
        paid: 500.00
      )
      duplicate = UtilityProviderBalanceSheet.new(
        utility_provider: utility_provider,
        property: property,
        month: Date.today.beginning_of_month,
        due_date: Date.today + 1.day,
        owed: 600.00,
        paid: 600.00
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:utility_provider_id]).to be_present
    end
  end

  describe "#balance" do
    it "calculates balance as owed minus paid" do
      balance_sheet = UtilityProviderBalanceSheet.create!(
        utility_provider: utility_provider,
        property: property,
        month: Date.today.beginning_of_month,
        due_date: Date.today,
        owed: 500.00,
        paid: 400.00
      )
      expect(balance_sheet.balance).to eq(100.00)
    end
  end
end
