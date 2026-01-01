require "rails_helper"

RSpec.describe UtilityType, type: :model do
  describe "associations" do
    it "has many utility_provider_utility_types" do
      utility_type = UtilityType.reflect_on_association(:utility_provider_utility_types)
      expect(utility_type).not_to be_nil
      expect(utility_type.macro).to eq(:has_many)
    end

    it "has many utility_providers through utility_provider_utility_types" do
      utility_type = UtilityType.reflect_on_association(:utility_providers)
      expect(utility_type).not_to be_nil
      expect(utility_type.macro).to eq(:has_many)
    end
  end

  describe "validations" do
    it "is valid with a name" do
      utility_type = UtilityType.new(name: "Heating")
      expect(utility_type).to be_valid
    end

    it "requires a name" do
      utility_type = UtilityType.new
      expect(utility_type).not_to be_valid
      expect(utility_type.errors[:name]).to include("can't be blank")
    end

    it "requires unique name" do
      UtilityType.create!(name: "Heating")
      duplicate = UtilityType.new(name: "Heating")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end
  end
end
