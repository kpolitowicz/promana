require "rails_helper"

RSpec.describe UtilityProviderBalanceSheetCalculator do
  fixtures :properties, :utility_providers

  let(:property) { properties(:property_one) }
  let(:utility_provider) { utility_providers(:utility_provider_one) }
  let(:calculator) { UtilityProviderBalanceSheetCalculator.new(utility_provider) }

  describe "#calculate_owed_for_month" do
    it "sums forecast line items due in the month" do
      month = Date.today.beginning_of_month
      forecast = Forecast.create!(
        utility_provider: utility_provider,
        property: property,
        issued_date: month
      )
      ForecastLineItem.create!(
        forecast: forecast,
        name: "Forecast",
        amount: 300.00,
        due_date: Date.new(month.year, month.month, 10)
      )
      ForecastLineItem.create!(
        forecast: forecast,
        name: "Settlement",
        amount: 50.00,
        due_date: Date.new(month.year, month.month, 15)
      )

      owed = calculator.calculate_owed_for_month(month)
      expect(owed).to eq(350.00)
    end

    it "returns 0 when no forecasts exist" do
      month = Date.today.beginning_of_month
      owed = calculator.calculate_owed_for_month(month)
      expect(owed).to eq(0.0)
    end
  end

  describe "#calculate_paid_for_month" do
    it "sums utility payments where paid_date falls within the month" do
      month = Date.today.beginning_of_month
      UtilityPayment.create!(
        utility_provider: utility_provider,
        property: property,
        amount: 200.00,
        paid_date: Date.new(month.year, month.month, 5)
      )
      UtilityPayment.create!(
        utility_provider: utility_provider,
        property: property,
        amount: 150.00,
        paid_date: Date.new(month.year, month.month, 20)
      )

      paid = calculator.calculate_paid_for_month(month)
      expect(paid).to eq(350.00)
    end
  end

  describe "#update_balance_sheet_for_month" do
    it "creates a new balance sheet entry if it doesn't exist" do
      month = Date.today.beginning_of_month
      forecast = Forecast.create!(
        utility_provider: utility_provider,
        property: property,
        issued_date: month
      )
      ForecastLineItem.create!(
        forecast: forecast,
        name: "Forecast",
        amount: 500.00,
        due_date: Date.new(month.year, month.month, 10)
      )

      UtilityPayment.create!(
        utility_provider: utility_provider,
        property: property,
        amount: 400.00,
        paid_date: Date.new(month.year, month.month, 15)
      )

      balance_sheet = calculator.update_balance_sheet_for_month(month, allow_update: true)

      expect(balance_sheet).to be_persisted
      expect(balance_sheet.owed).to eq(500.00)
      expect(balance_sheet.paid).to eq(400.00)
      expect(balance_sheet.balance).to eq(100.00)
    end
  end
end
