require "rails_helper"

RSpec.describe UtilityPayment, type: :model do
  fixtures :properties, :utility_providers

  let(:property) { properties(:property_one) }
  let(:utility_provider) { utility_providers(:utility_provider_one) }

  describe "associations" do
    it "belongs to utility_provider" do
      association = UtilityPayment.reflect_on_association(:utility_provider)
      expect(association).not_to be_nil
      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to property" do
      association = UtilityPayment.reflect_on_association(:property)
      expect(association).not_to be_nil
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "is valid with amount and paid_date" do
      payment = UtilityPayment.new(utility_provider: utility_provider, property: property, amount: 1000.00, paid_date: Date.today)
      expect(payment).to be_valid
    end

    it "requires amount" do
      payment = UtilityPayment.new(utility_provider: utility_provider, property: property, paid_date: Date.today)
      expect(payment).not_to be_valid
      expect(payment.errors[:amount]).to include("can't be blank")
    end

    it "requires paid_date" do
      payment = UtilityPayment.new(utility_provider: utility_provider, property: property, amount: 1000.00)
      expect(payment).not_to be_valid
      expect(payment.errors[:paid_date]).to include("can't be blank")
    end
  end
end
