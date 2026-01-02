require "rails_helper"

RSpec.describe ForecastLineItem, type: :model do
  let(:property) { Property.create!(name: "Test Property") }
  let(:utility_provider) { UtilityProvider.create!(name: "Test Provider", forecast_behavior: "zero_after_expiry", property: property) }
  let(:forecast) { Forecast.create!(utility_provider: utility_provider, property: property, issued_date: Date.today) }

  describe "associations" do
    it "belongs to forecast" do
      line_item = ForecastLineItem.reflect_on_association(:forecast)
      expect(line_item).not_to be_nil
      expect(line_item.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "is valid with name, amount, and due_date" do
      line_item = ForecastLineItem.new(
        forecast: forecast,
        name: "Forecast",
        amount: 100.50,
        due_date: Date.today
      )
      expect(line_item).to be_valid
    end

    it "requires name" do
      line_item = ForecastLineItem.new(forecast: forecast, amount: 100.50, due_date: Date.today)
      expect(line_item).not_to be_valid
      expect(line_item.errors[:name]).to include("can't be blank")
    end

    it "requires amount" do
      line_item = ForecastLineItem.new(forecast: forecast, name: "Forecast", due_date: Date.today)
      expect(line_item).not_to be_valid
      expect(line_item.errors[:amount]).to include("can't be blank")
    end

    it "requires due_date" do
      line_item = ForecastLineItem.new(forecast: forecast, name: "Forecast", amount: 100.50)
      expect(line_item).not_to be_valid
      expect(line_item.errors[:due_date]).to include("can't be blank")
    end

    it "allows negative amounts (for differences/refunds)" do
      line_item = ForecastLineItem.new(forecast: forecast, name: "Rozliczenie", amount: -20.50, due_date: Date.today)
      expect(line_item).to be_valid
    end

    it "allows amount to be 0" do
      line_item = ForecastLineItem.new(forecast: forecast, name: "Forecast", amount: 0, due_date: Date.today)
      expect(line_item).to be_valid
    end
  end
end
