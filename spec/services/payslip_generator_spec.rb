require "rails_helper"

RSpec.describe PayslipGenerator do
  let(:property) { Property.create!(name: "Test Property") }
  let(:tenant) { Tenant.create!(name: "Test Tenant") }
  let(:property_tenant) { PropertyTenant.create!(property: property, tenant: tenant, rent_amount: 1000.00) }
  let(:target_month) { Date.today.next_month.beginning_of_month }

  describe "#generate" do
    context "with no utility providers" do
      it "generates payslip with only rent" do
        generator = PayslipGenerator.new(property_tenant, month: target_month)
        result = generator.generate

        expect(result[:line_items].length).to eq(1)
        expect(result[:line_items].first[:name]).to eq("Rent")
        expect(result[:line_items].first[:amount]).to eq(1000.00)
      end
    end

    context "with utility provider and active forecast" do
      let(:utility_provider) { UtilityProvider.create!(name: "Test Provider", forecast_behavior: "zero_after_expiry", property: property) }
      let(:forecast) { Forecast.create!(utility_provider: utility_provider, property: property, issued_date: Date.today) }

      it "includes utility amount from active forecast" do
        ForecastLineItem.create!(forecast: forecast, name: "Forecast", amount: 250.00, due_date: target_month + 5.days)

        generator = PayslipGenerator.new(property_tenant, month: target_month)
        result = generator.generate

        expect(result[:line_items].length).to eq(2)
        expect(result[:line_items].map { |item| item[:name] }).to contain_exactly("Rent", "Test Provider")
        utility_item = result[:line_items].find { |item| item[:name] == "Test Provider" }
        expect(utility_item[:amount]).to eq(250.00)
      end

      it "sums multiple line items from active forecast" do
        ForecastLineItem.create!(forecast: forecast, name: "Forecast", amount: 200.00, due_date: target_month + 5.days)
        ForecastLineItem.create!(forecast: forecast, name: "Rozliczenie", amount: 50.00, due_date: target_month + 10.days)

        generator = PayslipGenerator.new(property_tenant, month: target_month)
        result = generator.generate

        utility_item = result[:line_items].find { |item| item[:name] == "Test Provider" }
        expect(utility_item[:amount]).to eq(250.00)
      end
    end

    context "with zero_after_expiry behavior and no active forecast" do
      let(:utility_provider) { UtilityProvider.create!(name: "Test Provider", forecast_behavior: "zero_after_expiry", property: property) }

      it "excludes utility from payslip" do
        generator = PayslipGenerator.new(property_tenant, month: target_month)
        result = generator.generate

        expect(result[:line_items].length).to eq(1)
        expect(result[:line_items].first[:name]).to eq("Rent")
      end
    end

    context "with carry_forward behavior and no active forecast" do
      let(:utility_provider) { UtilityProvider.create!(name: "Test Provider", forecast_behavior: "carry_forward", property: property) }
      let(:old_forecast) { Forecast.create!(utility_provider: utility_provider, property: property, issued_date: Date.today - 2.months) }

      it "carries forward amount from last forecast" do
        ForecastLineItem.create!(forecast: old_forecast, name: "Forecast", amount: 300.00, due_date: Date.today.beginning_of_month - 5.days)

        generator = PayslipGenerator.new(property_tenant, month: target_month)
        result = generator.generate

        utility_item = result[:line_items].find { |item| item[:name] == "Test Provider" }
        expect(utility_item[:amount]).to eq(300.00)
      end

      it "excludes utility if no previous forecast exists" do
        generator = PayslipGenerator.new(property_tenant, month: target_month)
        result = generator.generate

        expect(result[:line_items].length).to eq(1)
        expect(result[:line_items].first[:name]).to eq("Rent")
      end
    end

    context "with multiple utility providers" do
      let(:provider1) { UtilityProvider.create!(name: "Provider 1", forecast_behavior: "zero_after_expiry", property: property) }
      let(:provider2) { UtilityProvider.create!(name: "Provider 2", forecast_behavior: "carry_forward", property: property) }
      let(:forecast1) { Forecast.create!(utility_provider: provider1, property: property, issued_date: Date.today) }
      let(:old_forecast2) { Forecast.create!(utility_provider: provider2, property: property, issued_date: Date.today - 2.months) }

      it "includes utilities from all providers" do
        ForecastLineItem.create!(forecast: forecast1, name: "Forecast", amount: 150.00, due_date: target_month + 5.days)
        ForecastLineItem.create!(forecast: old_forecast2, name: "Forecast", amount: 200.00, due_date: Date.today.beginning_of_month - 5.days)

        generator = PayslipGenerator.new(property_tenant, month: target_month)
        result = generator.generate

        expect(result[:line_items].length).to eq(3)
        expect(result[:line_items].map { |item| item[:name] }).to contain_exactly("Rent", "Provider 1", "Provider 2")
      end
    end

    context "with custom month and due_date" do
      it "uses provided month and due_date" do
        custom_month = Date.today + 2.months
        custom_due_date = Date.new(custom_month.year, custom_month.month, 15)

        generator = PayslipGenerator.new(property_tenant, month: custom_month, due_date: custom_due_date)
        result = generator.generate

        expect(result[:month]).to eq(custom_month)
        expect(result[:due_date]).to eq(custom_due_date)
      end
    end
  end
end
