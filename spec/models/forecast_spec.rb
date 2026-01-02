require "rails_helper"

RSpec.describe Forecast, type: :model do
  fixtures :properties, :utility_providers

  let(:property) { properties(:property_one) }
  let(:utility_provider) { utility_providers(:utility_provider_one) }

  describe "associations" do
    it "belongs to utility_provider" do
      forecast = Forecast.reflect_on_association(:utility_provider)
      expect(forecast).not_to be_nil
      expect(forecast.macro).to eq(:belongs_to)
    end

    it "belongs to property" do
      forecast = Forecast.reflect_on_association(:property)
      expect(forecast).not_to be_nil
      expect(forecast.macro).to eq(:belongs_to)
    end

    it "has many forecast_line_items" do
      forecast = Forecast.reflect_on_association(:forecast_line_items)
      expect(forecast).not_to be_nil
      expect(forecast.macro).to eq(:has_many)
    end
  end

  describe "validations" do
    it "is valid with issued_date" do
      forecast = Forecast.new(utility_provider: utility_provider, property: property, issued_date: Date.today)
      expect(forecast).to be_valid
    end

    it "requires issued_date" do
      forecast = Forecast.new(utility_provider: utility_provider, property: property)
      expect(forecast).not_to be_valid
      expect(forecast.errors[:issued_date]).to include("can't be blank")
    end
  end

  describe "nested attributes" do
    it "accepts nested attributes for forecast_line_items" do
      forecast = Forecast.new(
        utility_provider: utility_provider,
        property: property,
        issued_date: Date.today,
        forecast_line_items_attributes: [
          {name: "Forecast", amount: 100.50, due_date: Date.today}
        ]
      )
      expect(forecast).to be_valid
      expect(forecast.forecast_line_items.size).to eq(1)
    end
  end
end
