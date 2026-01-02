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

      it "includes each forecast line item individually" do
        ForecastLineItem.create!(forecast: forecast, name: "Forecast", amount: 250.00, due_date: target_month + 5.days)

        generator = PayslipGenerator.new(property_tenant, month: target_month)
        result = generator.generate

        expect(result[:line_items].length).to eq(2)
        expect(result[:line_items].map { |item| item[:name] }).to contain_exactly("Rent", "Test Provider - Forecast")
        utility_item = result[:line_items].find { |item| item[:name] == "Test Provider - Forecast" }
        expect(utility_item[:amount]).to eq(250.00)
      end

      it "includes all line items from active forecast as separate items" do
        ForecastLineItem.create!(forecast: forecast, name: "Forecast", amount: 200.00, due_date: target_month + 5.days)
        ForecastLineItem.create!(forecast: forecast, name: "Rozliczenie", amount: 50.00, due_date: target_month + 10.days)

        generator = PayslipGenerator.new(property_tenant, month: target_month)
        result = generator.generate

        expect(result[:line_items].length).to eq(3)
        expect(result[:line_items].map { |item| item[:name] }).to contain_exactly("Rent", "Test Provider - Forecast", "Test Provider - Rozliczenie")
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
        expect(result[:line_items].first[:name]).to eq("Rent")
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
        expect(result[:line_items].first[:name]).to eq("Rent")
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
        expect(result[:line_items].map { |item| item[:name] }).to contain_exactly("Rent", "Provider 1 - Forecast", "Provider 2 - Forecast")
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
          january_payslip.payslip_line_items.create!(name: "Rent", amount: 2000.00)

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
          january_payslip.payslip_line_items.create!(name: "Rent", amount: 2000.00)

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
          january_payslip.payslip_line_items.create!(name: "Rent", amount: 2000.00)

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
          january_payslip.payslip_line_items.create!(name: "Rent", amount: 2000.00)

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
  end
end
