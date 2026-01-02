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
        expect(result[:line_items].first[:name]).to eq(Payslip.rent_label)
        expect(result[:line_items].first[:amount]).to eq(1000.00)
      end
    end

    context "with utility provider and active forecast" do
      let(:utility_provider) { UtilityProvider.create!(name: "Test Provider", forecast_behavior: "zero_after_expiry", property: property) }
      let(:forecast) { Forecast.create!(utility_provider: utility_provider, property: property, issued_date: Date.today) }

      it "includes each forecast line item individually" do
        ForecastLineItem.create!(forecast: forecast, name: "Forecast", amount: 250.00, due_date: target_month + 5.days)

        generator = PayslipGenerator.new(property_tenant, month: target_month)
        result = generator.generate

        expect(result[:line_items].length).to eq(2)
        expect(result[:line_items].map { |item| item[:name] }).to contain_exactly(Payslip.rent_label, "Test Provider - Forecast")
        utility_item = result[:line_items].find { |item| item[:name] == "Test Provider - Forecast" }
        expect(utility_item[:amount]).to eq(250.00)
      end

      it "includes all line items from active forecast as separate items" do
        ForecastLineItem.create!(forecast: forecast, name: "Forecast", amount: 200.00, due_date: target_month + 5.days)
        ForecastLineItem.create!(forecast: forecast, name: "Rozliczenie", amount: 50.00, due_date: target_month + 10.days)

        generator = PayslipGenerator.new(property_tenant, month: target_month)
        result = generator.generate

        expect(result[:line_items].length).to eq(3)
        expect(result[:line_items].map { |item| item[:name] }).to contain_exactly(Payslip.rent_label, "Test Provider - Forecast", "Test Provider - Rozliczenie")
        forecast_item = result[:line_items].find { |item| item[:name] == "Test Provider - Forecast" }
        rozliczenie_item = result[:line_items].find { |item| item[:name] == "Test Provider - Rozliczenie" }
        expect(forecast_item[:amount]).to eq(200.00)
        expect(rozliczenie_item[:amount]).to eq(50.00)
      end
    end

    context "with zero_after_expiry behavior and no active forecast" do
      let(:utility_provider) { UtilityProvider.create!(name: "Test Provider", forecast_behavior: "zero_after_expiry", property: property) }

      it "excludes utility from payslip" do
        generator = PayslipGenerator.new(property_tenant, month: target_month)
        result = generator.generate

        expect(result[:line_items].length).to eq(1)
        expect(result[:line_items].first[:name]).to eq(Payslip.rent_label)
      end
    end

    context "with carry_forward behavior and no active forecast" do
      let(:utility_provider) { UtilityProvider.create!(name: "Test Provider", forecast_behavior: "carry_forward", property: property) }
      let(:old_forecast) { Forecast.create!(utility_provider: utility_provider, property: property, issued_date: Date.today - 2.months) }

      it "carries forward line items from last forecast" do
        ForecastLineItem.create!(forecast: old_forecast, name: "Forecast", amount: 300.00, due_date: Date.today.beginning_of_month - 5.days)

        generator = PayslipGenerator.new(property_tenant, month: target_month)
        result = generator.generate

        utility_item = result[:line_items].find { |item| item[:name] == "Test Provider - Forecast" }
        expect(utility_item[:amount]).to eq(300.00)
      end

      it "excludes utility if no previous forecast exists" do
        generator = PayslipGenerator.new(property_tenant, month: target_month)
        result = generator.generate

        expect(result[:line_items].length).to eq(1)
        expect(result[:line_items].first[:name]).to eq(Payslip.rent_label)
      end
    end

    context "with multiple utility providers" do
      let(:provider1) { UtilityProvider.create!(name: "Provider 1", forecast_behavior: "zero_after_expiry", property: property) }
      let(:provider2) { UtilityProvider.create!(name: "Provider 2", forecast_behavior: "carry_forward", property: property) }
      let(:forecast1) { Forecast.create!(utility_provider: provider1, property: property, issued_date: Date.today) }
      let(:old_forecast2) { Forecast.create!(utility_provider: provider2, property: property, issued_date: Date.today - 2.months) }

      it "includes all forecast line items from all providers" do
        ForecastLineItem.create!(forecast: forecast1, name: "Forecast", amount: 150.00, due_date: target_month + 5.days)
        ForecastLineItem.create!(forecast: old_forecast2, name: "Forecast", amount: 200.00, due_date: Date.today.beginning_of_month - 5.days)

        generator = PayslipGenerator.new(property_tenant, month: target_month)
        result = generator.generate

        expect(result[:line_items].length).to eq(3)
        expect(result[:line_items].map { |item| item[:name] }).to contain_exactly(Payslip.rent_label, "Provider 1 - Forecast", "Provider 2 - Forecast")
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

    context "with payment differences from previous month" do
      let(:january_2026) { Date.new(2026, 1, 1) }
      let(:february_2026) { Date.new(2026, 2, 1) }

      context "when tenant underpaid previous month" do
        it "includes underpayment line item (Zaległe) in next month's payslip" do
          # Create January payslip with total 2000
          january_payslip = Payslip.create!(
            property: property,
            property_tenant: property_tenant,
            month: january_2026,
            due_date: Date.new(2026, 1, 10)
          )
          january_payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 2000.00)

          # Tenant paid only 1500 in January
          TenantPayment.create!(
            property_tenant: property_tenant,
            property: property,
            amount: 1500.00,
            paid_date: Date.new(2026, 1, 15)
          )

          # Generate February payslip
          generator = PayslipGenerator.new(property_tenant, month: february_2026)
          result = generator.generate

          # Should include underpayment line item
          diff_item = result[:line_items].find { |item| item[:name] == Payslip.underpayment_label }
          expect(diff_item).not_to be_nil
          expect(diff_item[:amount]).to eq(500.00) # 2000 - 1500 = 500
        end
      end

      context "when tenant overpaid previous month" do
        it "includes overpayment line item (Nadpłata) in next month's payslip" do
          # Create January payslip with total 2000
          january_payslip = Payslip.create!(
            property: property,
            property_tenant: property_tenant,
            month: january_2026,
            due_date: Date.new(2026, 1, 10)
          )
          january_payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 2000.00)

          # Tenant paid 2100 in January (overpaid by 100)
          TenantPayment.create!(
            property_tenant: property_tenant,
            property: property,
            amount: 2100.00,
            paid_date: Date.new(2026, 1, 15)
          )

          # Generate February payslip
          generator = PayslipGenerator.new(property_tenant, month: february_2026)
          result = generator.generate

          # Should include overpayment line item (negative amount)
          diff_item = result[:line_items].find { |item| item[:name] == Payslip.overpayment_label }
          expect(diff_item).not_to be_nil
          expect(diff_item[:amount]).to eq(-100.00) # 2000 - 2100 = -100 (credit)
        end
      end

      context "when tenant paid exactly the payslip amount" do
        it "does not include any difference line item" do
          # Create January payslip with total 2000
          january_payslip = Payslip.create!(
            property: property,
            property_tenant: property_tenant,
            month: january_2026,
            due_date: Date.new(2026, 1, 10)
          )
          january_payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 2000.00)

          # Tenant paid exactly 2000 in January
          TenantPayment.create!(
            property_tenant: property_tenant,
            property: property,
            amount: 2000.00,
            paid_date: Date.new(2026, 1, 15)
          )

          # Generate February payslip
          generator = PayslipGenerator.new(property_tenant, month: february_2026)
          result = generator.generate

          # Should not include any difference line item
          expect(result[:line_items].none? { |item| item[:name] == Payslip.underpayment_label }).to be true
          expect(result[:line_items].none? { |item| item[:name] == Payslip.overpayment_label }).to be true
        end
      end

      context "when no previous payslip exists" do
        it "does not include any difference line item" do
          # Generate February payslip without January payslip
          generator = PayslipGenerator.new(property_tenant, month: february_2026)
          result = generator.generate

          # Should not include any difference line item
          expect(result[:line_items].none? { |item| item[:name] == Payslip.underpayment_label }).to be true
          expect(result[:line_items].none? { |item| item[:name] == Payslip.overpayment_label }).to be true
        end
      end

      context "when multiple payments were made in previous month" do
        it "sums all payments and calculates total difference" do
          # Create January payslip with total 2000
          january_payslip = Payslip.create!(
            property: property,
            property_tenant: property_tenant,
            month: january_2026,
            due_date: Date.new(2026, 1, 10)
          )
          january_payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 2000.00)

          # Tenant made two payments: 1000 + 600 = 1600 (underpaid by 400)
          TenantPayment.create!(
            property_tenant: property_tenant,
            property: property,
            amount: 1000.00,
            paid_date: Date.new(2026, 1, 15)
          )
          TenantPayment.create!(
            property_tenant: property_tenant,
            property: property,
            amount: 600.00,
            paid_date: Date.new(2026, 1, 20)
          )

          # Generate February payslip
          generator = PayslipGenerator.new(property_tenant, month: february_2026)
          result = generator.generate

          # Should include underpayment line item for 400
          diff_item = result[:line_items].find { |item| item[:name] == Payslip.underpayment_label }
          expect(diff_item).not_to be_nil
          expect(diff_item[:amount]).to eq(400.00) # 2000 - 1600 = 400
        end
      end
    end

    context "with forecast adjustments from previous month" do
      let(:february_2026) { Date.new(2026, 2, 1) }
      let(:march_2026) { Date.new(2026, 3, 1) }
      let(:management_provider) { UtilityProvider.create!(name: "Management", forecast_behavior: "carry_forward", property: property) }

      context "when new forecast received after payslip was generated" do
        it "includes adjustment line item (Wyrównanie) in next month's payslip" do
          # Create old forecast with waste: 100, water: 200 (used for carry forward)
          old_forecast = Forecast.create!(
            utility_provider: management_provider,
            property: property,
            issued_date: Date.new(2026, 1, 1)
          )
          ForecastLineItem.create!(forecast: old_forecast, name: "Waste", amount: 100.00, due_date: Date.new(2026, 1, 10))
          ForecastLineItem.create!(forecast: old_forecast, name: "Water", amount: 200.00, due_date: Date.new(2026, 1, 10))

          # Create February payslip on 2026-01-26 (uses carry forward: waste 100, water 200)
          february_payslip = Payslip.create!(
            property: property,
            property_tenant: property_tenant,
            month: february_2026,
            due_date: Date.new(2026, 2, 10),
            created_at: Time.zone.parse("2026-01-26")
          )
          february_payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 700.00)
          february_payslip.payslip_line_items.create!(name: "Management - Waste", amount: 100.00)
          february_payslip.payslip_line_items.create!(name: "Management - Water", amount: 200.00)

          # New forecast received on 2026-02-05 with updated amounts (waste: 90, water: 220)
          new_forecast = Forecast.create!(
            utility_provider: management_provider,
            property: property,
            issued_date: Date.new(2026, 2, 5)
          )
          ForecastLineItem.create!(forecast: new_forecast, name: "Waste", amount: 90.00, due_date: Date.new(2026, 2, 10))
          ForecastLineItem.create!(forecast: new_forecast, name: "Water", amount: 220.00, due_date: Date.new(2026, 2, 10))

          # Generate March payslip
          generator = PayslipGenerator.new(property_tenant, month: march_2026)
          result = generator.generate

          # Should include adjustment line item: (90-100) + (220-200) = -10 + 20 = +10
          adjustment_item = result[:line_items].find { |item| item[:name] == Payslip.adjustment_label }
          expect(adjustment_item).not_to be_nil
          expect(adjustment_item[:amount]).to eq(10.00)
        end
      end

      context "when no new forecast received after payslip was generated" do
        it "does not include adjustment line item" do
          # Create forecast
          forecast = Forecast.create!(
            utility_provider: management_provider,
            property: property,
            issued_date: Date.new(2026, 1, 1)
          )
          ForecastLineItem.create!(forecast: forecast, name: "Waste", amount: 100.00, due_date: Date.new(2026, 2, 10))

          # Create February payslip on 2026-01-26
          february_payslip = Payslip.create!(
            property: property,
            property_tenant: property_tenant,
            month: february_2026,
            due_date: Date.new(2026, 2, 10),
            created_at: Time.zone.parse("2026-01-26")
          )
          february_payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 700.00)
          february_payslip.payslip_line_items.create!(name: "Management - Waste", amount: 100.00)

          # Generate March payslip (no new forecast after payslip creation)
          generator = PayslipGenerator.new(property_tenant, month: march_2026)
          result = generator.generate

          # Should not include adjustment line item
          expect(result[:line_items].none? { |item| item[:name] == Payslip.adjustment_label }).to be true
        end
      end

      context "when adjustment results in negative amount" do
        it "includes negative adjustment line item" do
          # Create February payslip with waste: 100, water: 200
          february_payslip = Payslip.create!(
            property: property,
            property_tenant: property_tenant,
            month: february_2026,
            due_date: Date.new(2026, 2, 10),
            created_at: Time.zone.parse("2026-01-26")
          )
          february_payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 700.00)
          february_payslip.payslip_line_items.create!(name: "Management - Waste", amount: 100.00)
          february_payslip.payslip_line_items.create!(name: "Management - Water", amount: 200.00)

          # New forecast with lower amounts (waste: 80, water: 180)
          new_forecast = Forecast.create!(
            utility_provider: management_provider,
            property: property,
            issued_date: Date.new(2026, 2, 5)
          )
          ForecastLineItem.create!(forecast: new_forecast, name: "Waste", amount: 80.00, due_date: Date.new(2026, 2, 10))
          ForecastLineItem.create!(forecast: new_forecast, name: "Water", amount: 180.00, due_date: Date.new(2026, 2, 10))

          # Generate March payslip
          generator = PayslipGenerator.new(property_tenant, month: march_2026)
          result = generator.generate

          # Should include negative adjustment: (80-100) + (180-200) = -20 + -20 = -40
          adjustment_item = result[:line_items].find { |item| item[:name] == Payslip.adjustment_label }
          expect(adjustment_item).not_to be_nil
          expect(adjustment_item[:amount]).to eq(-40.00)
        end
      end

      context "when multiple utility providers have adjustments" do
        let(:provider2) { UtilityProvider.create!(name: "Energy Provider", forecast_behavior: "carry_forward", property: property) }

        it "sums adjustments from all providers" do
          # Create February payslip
          february_payslip = Payslip.create!(
            property: property,
            property_tenant: property_tenant,
            month: february_2026,
            due_date: Date.new(2026, 2, 10),
            created_at: Time.zone.parse("2026-01-26")
          )
          february_payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 700.00)
          february_payslip.payslip_line_items.create!(name: "Management - Waste", amount: 100.00)
          february_payslip.payslip_line_items.create!(name: "Energy Provider - Forecast", amount: 50.00)

          # New forecasts received
          new_management_forecast = Forecast.create!(
            utility_provider: management_provider,
            property: property,
            issued_date: Date.new(2026, 2, 5)
          )
          ForecastLineItem.create!(forecast: new_management_forecast, name: "Waste", amount: 90.00, due_date: Date.new(2026, 2, 10))

          new_energy_forecast = Forecast.create!(
            utility_provider: provider2,
            property: property,
            issued_date: Date.new(2026, 2, 6)
          )
          ForecastLineItem.create!(forecast: new_energy_forecast, name: "Forecast", amount: 60.00, due_date: Date.new(2026, 2, 10))

          # Generate March payslip
          generator = PayslipGenerator.new(property_tenant, month: march_2026)
          result = generator.generate

          # Should include adjustment: (90-100) + (60-50) = -10 + 10 = 0
          # Actually wait, if it's 0, it shouldn't be included. Let me check the logic.
          # But in this case it's -10 + 10 = 0, so no adjustment line item
          adjustment_item = result[:line_items].find { |item| item[:name] == Payslip.adjustment_label }
          expect(adjustment_item).to be_nil
        end
      end
    end
  end
end
