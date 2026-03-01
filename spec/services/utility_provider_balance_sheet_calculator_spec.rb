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

    context "with line item carry_forward" do
      let(:provider) { UtilityProvider.create!(name: "CF Provider", forecast_behavior: "zero_after_expiry", property: property) }
      let(:cf_calculator) { UtilityProviderBalanceSheetCalculator.new(provider) }

      it "carries forward only items marked carry_forward: true" do
        september = Date.new(2025, 9, 1)
        old_forecast = Forecast.create!(utility_provider: provider, property: property, issued_date: september)
        ForecastLineItem.create!(forecast: old_forecast, name: "Recurring", amount: 300.00, due_date: Date.new(2025, 9, 10), carry_forward: true)
        ForecastLineItem.create!(forecast: old_forecast, name: "Settlement", amount: 50.00, due_date: Date.new(2025, 9, 15), carry_forward: false)

        january_2026 = Date.new(2026, 1, 1)
        owed = cf_calculator.calculate_owed_for_month(january_2026)
        expect(owed).to eq(300.00) # Only the recurring item
      end

      it "returns 0 when no previous forecast exists" do
        owed = cf_calculator.calculate_owed_for_month(Date.today.beginning_of_month)
        expect(owed).to eq(0.0)
      end

      it "returns 0 when no items are marked carry_forward" do
        september = Date.new(2025, 9, 1)
        old_forecast = Forecast.create!(utility_provider: provider, property: property, issued_date: september)
        ForecastLineItem.create!(forecast: old_forecast, name: "Settlement", amount: 50.00, due_date: Date.new(2025, 9, 15), carry_forward: false)

        january_2026 = Date.new(2026, 1, 1)
        owed = cf_calculator.calculate_owed_for_month(january_2026)
        expect(owed).to eq(0.0)
      end
    end

    context "with zero_after_expiry behavior" do
      let(:zero_provider) { UtilityProvider.create!(name: "Zero Provider", forecast_behavior: "zero_after_expiry", property: property) }
      let(:zero_calculator) { UtilityProviderBalanceSheetCalculator.new(zero_provider) }

      it "returns 0 when no forecast exists for the month" do
        # Create a forecast for September 2025
        september = Date.new(2025, 9, 1)
        old_forecast = Forecast.create!(
          utility_provider: zero_provider,
          property: property,
          issued_date: september
        )
        ForecastLineItem.create!(
          forecast: old_forecast,
          name: "Forecast",
          amount: 300.00,
          due_date: Date.new(2025, 9, 10)
        )

        # Calculate for January 2026 (no forecast exists, should return 0)
        january_2026 = Date.new(2026, 1, 1)
        owed = zero_calculator.calculate_owed_for_month(january_2026)
        expect(owed).to eq(0.0)
      end
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

    it "does not create balance sheets for future months" do
      future_month = Date.today.beginning_of_month + 2.months

      # Create forecast with line item for future month
      forecast = Forecast.create!(
        utility_provider: utility_provider,
        property: property,
        issued_date: Date.today
      )
      ForecastLineItem.create!(
        forecast: forecast,
        name: "Forecast",
        amount: 500.00,
        due_date: Date.new(future_month.year, future_month.month, 10)
      )

      calculator.update_all_missing_months

      # Should not create balance sheet for future month
      future_sheet = UtilityProviderBalanceSheet.find_by(utility_provider: utility_provider, month: future_month)
      expect(future_sheet).to be_nil
    end
  end

  describe "#update_all_missing_months (next month row)" do
    include ActiveSupport::Testing::TimeHelpers

    it "creates next month balance sheet when current month has a payment registered (even if 0)" do
      travel_to Date.new(2026, 1, 30) do
        UtilityPayment.create!(
          utility_provider: utility_provider,
          property: property,
          amount: 0.00,
          paid_date: Date.new(2026, 1, 15)
        )
        Forecast.create!(
          utility_provider: utility_provider,
          property: property,
          issued_date: Date.new(2025, 12, 1)
        ).tap do |f|
          ForecastLineItem.create!(forecast: f, name: "Feb", amount: 200.00, due_date: Date.new(2026, 2, 10))
        end

        calculator.update_all_missing_months

        feb_sheet = UtilityProviderBalanceSheet.find_by(utility_provider: utility_provider, month: Date.new(2026, 2, 1))
        expect(feb_sheet).to be_present
        expect(feb_sheet.owed).to eq(200.00)
        expect(feb_sheet.paid).to eq(0.00)
      end
    end

    it "does not create next month balance sheet when current month has no payment registered" do
      travel_to Date.new(2026, 1, 30) do
        # No payment for January
        calculator.update_all_missing_months

        feb_sheet = UtilityProviderBalanceSheet.find_by(utility_provider: utility_provider, month: Date.new(2026, 2, 1))
        expect(feb_sheet).to be_nil
      end
    end
  end
end
