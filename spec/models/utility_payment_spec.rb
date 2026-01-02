require "rails_helper"

RSpec.describe UtilityPayment, type: :model do
  let(:property) { Property.create!(name: "Test Property") }
  let(:utility_provider) { UtilityProvider.create!(property: property, name: "Test Provider", forecast_behavior: "zero_after_expiry") }

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
    it "is valid with month, amount, and paid_date" do
      payment = UtilityPayment.new(utility_provider: utility_provider, property: property, month: Date.today, amount: 1000.00, paid_date: Date.today)
      expect(payment).to be_valid
    end

    it "requires month" do
      payment = UtilityPayment.new(utility_provider: utility_provider, property: property, amount: 1000.00, paid_date: Date.today)
      expect(payment).not_to be_valid
      expect(payment.errors[:month]).to include("can't be blank")
    end

    it "requires amount" do
      payment = UtilityPayment.new(utility_provider: utility_provider, property: property, month: Date.today, paid_date: Date.today)
      expect(payment).not_to be_valid
      expect(payment.errors[:amount]).to include("can't be blank")
    end

    it "requires paid_date" do
      payment = UtilityPayment.new(utility_provider: utility_provider, property: property, month: Date.today, amount: 1000.00)
      expect(payment).not_to be_valid
      expect(payment.errors[:paid_date]).to include("can't be blank")
    end

    it "requires unique utility_provider and month combination" do
      UtilityPayment.create!(utility_provider: utility_provider, property: property, month: Date.today.beginning_of_month, amount: 1000.00, paid_date: Date.today)
      duplicate = UtilityPayment.new(utility_provider: utility_provider, property: property, month: Date.today.beginning_of_month, amount: 2000.00, paid_date: Date.today)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:utility_provider_id]).to include("has already been taken")
    end
  end
end
