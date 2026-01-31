require "rails_helper"

RSpec.describe UtilityProvider, type: :model do
  fixtures :properties, :utility_providers

  let(:property) { properties(:property_one) }

  describe "associations" do
    it "belongs to property" do
      utility_provider = UtilityProvider.reflect_on_association(:property)
      expect(utility_provider).not_to be_nil
      expect(utility_provider.macro).to eq(:belongs_to)
    end

    it "has many utility_provider_utility_types" do
      utility_provider = UtilityProvider.reflect_on_association(:utility_provider_utility_types)
      expect(utility_provider).not_to be_nil
      expect(utility_provider.macro).to eq(:has_many)
    end

    it "has many utility_types through utility_provider_utility_types" do
      utility_provider = UtilityProvider.reflect_on_association(:utility_types)
      expect(utility_provider).not_to be_nil
      expect(utility_provider.macro).to eq(:has_many)
    end
  end

  describe "validations" do
    it "is valid with name, forecast_behavior, and property" do
      utility_provider = UtilityProvider.new(name: "Test Provider", forecast_behavior: "zero_after_expiry", property: property)
      expect(utility_provider).to be_valid
    end

    it "requires a name" do
      utility_provider = UtilityProvider.new(forecast_behavior: "zero_after_expiry", property: property)
      expect(utility_provider).not_to be_valid
      expect(utility_provider.errors[:name]).to include("can't be blank")
    end

    it "requires forecast_behavior" do
      utility_provider = UtilityProvider.new(name: "Test Provider", property: property)
      expect(utility_provider).not_to be_valid
      expect(utility_provider.errors[:forecast_behavior]).to include("can't be blank")
    end

    it "validates uniqueness of name scoped to property_id" do
      # Fixture already creates utility_provider_one with name "Test Provider 1" for property_one
      # Try to create duplicate with same name
      duplicate = UtilityProvider.new(name: "Test Provider 1", forecast_behavior: "carry_forward", property: property)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    it "allows same name for different properties" do
      property2 = properties(:property_two)
      # Use a unique name that doesn't conflict with fixtures
      duplicate = UtilityProvider.new(name: "Unique Provider Name", forecast_behavior: "zero_after_expiry", property: property2)
      expect(duplicate).to be_valid
    end
  end

  describe "enum" do
    it "has forecast_behavior enum" do
      utility_provider = UtilityProvider.create!(name: "Test Provider", forecast_behavior: "zero_after_expiry", property: property)
      expect(utility_provider.zero_after_expiry?).to be true
      expect(utility_provider.carry_forward?).to be false

      utility_provider.update!(forecast_behavior: "carry_forward")
      expect(utility_provider.carry_forward?).to be true
      expect(utility_provider.zero_after_expiry?).to be false
    end
  end

  describe "#next_payment_owed" do
    include ActiveSupport::Testing::TimeHelpers

    let(:utility_provider) { utility_providers(:utility_provider_one) }

    it "returns owed from the next month when only next month has a balance sheet row" do
      travel_to Date.new(2026, 1, 30) do
        UtilityProviderBalanceSheet.create!(
          utility_provider: utility_provider,
          property: property,
          month: Date.new(2026, 2, 1),
          due_date: Date.new(2026, 2, 10),
          owed: 150.00,
          paid: 0.00
        )

        expect(utility_provider.next_payment_owed).to eq(150.00)
      end
    end

    it "returns current month's owed when current month has a row but next month does not" do
      travel_to Date.new(2026, 1, 15) do
        UtilityProviderBalanceSheet.create!(
          utility_provider: utility_provider,
          property: property,
          month: Date.new(2026, 1, 1),
          due_date: Date.new(2026, 1, 10),
          owed: 200.00,
          paid: 0.00
        )

        expect(utility_provider.next_payment_owed).to eq(200.00)
      end
    end

    it "returns the next month's owed when both current and next month have rows" do
      travel_to Date.new(2026, 1, 15) do
        UtilityProviderBalanceSheet.create!(
          utility_provider: utility_provider,
          property: property,
          month: Date.new(2026, 1, 1),
          due_date: Date.new(2026, 1, 10),
          owed: 100.00,
          paid: 0.00
        )
        UtilityProviderBalanceSheet.create!(
          utility_provider: utility_provider,
          property: property,
          month: Date.new(2026, 2, 1),
          due_date: Date.new(2026, 2, 10),
          owed: 250.00,
          paid: 0.00
        )

        expect(utility_provider.next_payment_owed).to eq(250.00)
      end
    end

    it "returns nil when neither current nor next month has a balance sheet row" do
      travel_to Date.new(2026, 1, 15) do
        # Only a past month row
        UtilityProviderBalanceSheet.create!(
          utility_provider: utility_provider,
          property: property,
          month: Date.new(2025, 12, 1),
          due_date: Date.new(2025, 12, 10),
          owed: 80.00,
          paid: 80.00
        )

        expect(utility_provider.next_payment_owed).to be_nil
      end
    end
  end
end
