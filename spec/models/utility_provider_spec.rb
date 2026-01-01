require "rails_helper"

RSpec.describe UtilityProvider, type: :model do
  let(:property) { Property.create!(name: "Test Property") }

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
      UtilityProvider.create!(name: "Test Provider", forecast_behavior: "zero_after_expiry", property: property)
      duplicate = UtilityProvider.new(name: "Test Provider", forecast_behavior: "carry_forward", property: property)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    it "allows same name for different properties" do
      property2 = Property.create!(name: "Test Property 2")
      UtilityProvider.create!(name: "Test Provider", forecast_behavior: "zero_after_expiry", property: property)
      duplicate = UtilityProvider.new(name: "Test Provider", forecast_behavior: "zero_after_expiry", property: property2)
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
end
