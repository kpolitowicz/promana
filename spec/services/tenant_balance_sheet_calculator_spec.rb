require "rails_helper"

RSpec.describe TenantBalanceSheetCalculator do
  fixtures :properties, :tenants, :property_tenants, :utility_providers

  let(:property) { properties(:property_one) }
  let(:property_tenant) { property_tenants(:property_tenant_one) }
  let(:calculator) { TenantBalanceSheetCalculator.new(property_tenant) }
  let(:utility_provider) { utility_providers(:utility_provider_one) }

  # Create a forecast with 2 items per each month
  # for different months starting with the given one.
  def create_forecast!(provider, month)
    forecast = Forecast.create!(
      utility_provider: utility_provider,
      property: property,
      issued_date: Date.new(month.year, month.month, 9)
    )
    ForecastLineItem.create!(
      forecast: forecast,
      name: "Forecast",
      amount: 100.00,
      due_date: Date.new(month.year, month.month, 10)
    )
    ForecastLineItem.create!(
      forecast: forecast,
      name: "Other",
      amount: 10.00,
      due_date: Date.new(month.year, month.month, 10)
    )
    ForecastLineItem.create!(
      forecast: forecast,
      name: "Forecast",
      amount: 200.00,
      due_date: Date.new(month.year, month.month, 10) + 1.month
    )
    ForecastLineItem.create!(
      forecast: forecast,
      name: "Other",
      amount: 20.00,
      due_date: Date.new(month.year, month.month, 10) + 1.month
    )
    ForecastLineItem.create!(
      forecast: forecast,
      name: "Forecast",
      amount: 400.00,
      due_date: Date.new(month.year, month.month, 10) + 2.months
    )
    ForecastLineItem.create!(
      forecast: forecast,
      name: "Other",
      amount: 40.00,
      due_date: Date.new(month.year, month.month, 10) + 2.months
    )
  end

  describe "#calculate_owed_for_month" do
    it "includes tenant's rent from payslip if available" do
      month = Date.today.beginning_of_month
      payslip = Payslip.create!(
        property: property,
        property_tenant: property_tenant,
        month: month,
        due_date: Date.new(month.year, month.month, 10)
      )
      payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 800.00)
      payslip.payslip_line_items.create!(name: "Utilities", amount: 250.00)

      owed = calculator.calculate_owed_for_month(month)
      expect(owed).to eq(800.00)
    end

    it "includes property current rent if no payslip" do
      month = Date.today.beginning_of_month
      owed = calculator.calculate_owed_for_month(month)
      expect(owed).to eq(1000.00)
    end

    context "when zero_after_expiry provider" do
      it "sums forecast items for the month" do
        month = Date.today.beginning_of_month

        create_forecast!(utility_provider, month - 1.month)

        owed = calculator.calculate_owed_for_month(month)
        expect(owed).to eq(1220.00)
      end

      it "returns rent amount only if no forecast items for the month" do
        month = Date.today.beginning_of_month

        create_forecast!(utility_provider, month - 3.months)

        owed = calculator.calculate_owed_for_month(month)
        expect(owed).to eq(1000.00)
      end
    end

    context "with line item carry_forward" do
      let(:cf_provider) { UtilityProvider.create!(name: "CF Provider", forecast_behavior: "zero_after_expiry", property: property) }

      it "carries forward only items marked carry_forward: true when no current forecast" do
        month = Date.today.beginning_of_month
        past_month = month - 1.month
        forecast = Forecast.create!(utility_provider: cf_provider, property: property, issued_date: past_month)
        ForecastLineItem.create!(forecast: forecast, name: "Recurring", amount: 200.00, due_date: Date.new(past_month.year, past_month.month, 10), carry_forward: true)
        ForecastLineItem.create!(forecast: forecast, name: "Settlement", amount: 50.00, due_date: Date.new(past_month.year, past_month.month, 10), carry_forward: false)

        owed = calculator.calculate_owed_for_month(month)
        expect(owed).to eq(1200.00) # rent 1000 + recurring 200 only
      end

      it "returns rent only if no carry_forward items exist" do
        month = Date.today.beginning_of_month
        past_month = month - 1.month
        forecast = Forecast.create!(utility_provider: cf_provider, property: property, issued_date: past_month)
        ForecastLineItem.create!(forecast: forecast, name: "Settlement", amount: 50.00, due_date: Date.new(past_month.year, past_month.month, 10), carry_forward: false)

        owed = calculator.calculate_owed_for_month(month)
        expect(owed).to eq(1000.00)
      end
    end
  end

  describe "#calculate_paid_for_month" do
    it "sums tenant payments where paid_date falls within the month" do
      month = Date.today.beginning_of_month
      TenantPayment.create!(
        property_tenant: property_tenant,
        property: property,
        amount: 500.00,
        paid_date: Date.new(month.year, month.month, 5)
      )
      TenantPayment.create!(
        property_tenant: property_tenant,
        property: property,
        amount: 300.00,
        paid_date: Date.new(month.year, month.month, 20)
      )

      paid = calculator.calculate_paid_for_month(month)
      expect(paid).to eq(800.00)
    end

    it "excludes payments from other months" do
      month = Date.today.beginning_of_month
      TenantPayment.create!(
        property_tenant: property_tenant,
        property: property,
        amount: 500.00,
        paid_date: month - 1.month
      )

      paid = calculator.calculate_paid_for_month(month)
      expect(paid).to eq(0.0)
    end
  end

  describe "#update_balance_sheet_for_month" do
    it "creates a new balance sheet entry if it doesn't exist" do
      month = Date.today.beginning_of_month
      create_forecast!(utility_provider, month)
      TenantPayment.create!(
        property_tenant: property_tenant,
        property: property,
        amount: 800.00,
        paid_date: Date.new(month.year, month.month, 15)
      )

      balance_sheet = calculator.update_balance_sheet_for_month(month, allow_update: true)

      expect(balance_sheet).to be_persisted
      expect(balance_sheet.owed).to eq(1110.00)
      expect(balance_sheet.paid).to eq(800.00)
      expect(balance_sheet.balance).to eq(310.00)
    end

    it "updates existing balance sheet when allow_update is true" do
      month = Date.today.beginning_of_month
      balance_sheet = TenantBalanceSheet.create!(
        property_tenant: property_tenant,
        property: property,
        month: month,
        due_date: Date.new(month.year, month.month, 10),
        owed: 1000.00,
        paid: 500.00
      )

      create_forecast!(utility_provider, month)
      TenantPayment.create!(
        property_tenant: property_tenant,
        property: property,
        amount: 1000.00,
        paid_date: Date.new(month.year, month.month, 15)
      )

      updated = calculator.update_balance_sheet_for_month(month, allow_update: true)

      expect(updated.id).to eq(balance_sheet.id)
      expect(updated.owed).to eq(1110.00)
      expect(updated.paid).to eq(1000.00)
    end

    it "does not update existing balance sheet when allow_update is false" do
      month = Date.today.beginning_of_month - 1.month
      balance_sheet = TenantBalanceSheet.create!(
        property_tenant: property_tenant,
        property: property,
        month: month,
        due_date: Date.new(month.year, month.month, 10),
        owed: 1000.00,
        paid: 500.00
      )

      result = calculator.update_balance_sheet_for_month(month, allow_update: false)

      expect(result.id).to eq(balance_sheet.id)
      expect(result.owed).to eq(1000.00) # Not updated
      expect(result.paid).to eq(500.00) # Not updated
    end
  end

  describe "#update_all_missing_months" do
    it "creates balance sheets for months with payslips" do
      # Use a date that's definitely in the past
      january = Date.new(2025, 1, 1)
      current_month = Date.today.beginning_of_month

      create_forecast!(utility_provider, january)

      calculator.update_all_missing_months

      # Should create balance sheet for January (if not current month) and current month
      balance_sheets = TenantBalanceSheet.where(property_tenant: property_tenant)
      expect(balance_sheets.count).to be >= 1
      january_sheet = TenantBalanceSheet.find_by(property_tenant: property_tenant, month: january)
      if january != current_month
        expect(january_sheet).not_to be_nil
        expect(january_sheet.owed).to eq(1110.00)
      end
    end

    it "updates current month but not past months" do
      # Use a date that's definitely in the past
      january = Date.new(2025, 1, 1)
      current_month = Date.today.beginning_of_month

      # Skip test if January 2025 is the current month (unlikely but possible)
      skip "January 2025 is current month" if january == current_month

      # Create existing balance sheet for January
      TenantBalanceSheet.create!(
        property_tenant: property_tenant,
        property: property,
        month: january,
        due_date: Date.new(2025, 1, 10),
        owed: 1000.00,
        paid: 500.00
      )

      # Create new payslip for January (should not update balance sheet)
      payslip = Payslip.create!(
        property: property,
        property_tenant: property_tenant,
        month: january,
        due_date: Date.new(2025, 1, 10)
      )
      payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 1500.00)

      calculator.update_all_missing_months

      january_sheet = TenantBalanceSheet.find_by(property_tenant: property_tenant, month: january)
      expect(january_sheet.owed).to eq(1000.00) # Not updated (past month)
    end

    it "does not create balance sheets for future months" do
      future_month = Date.today.beginning_of_month + 2.months

      # Create payslip for future month
      payslip = Payslip.create!(
        property: property,
        property_tenant: property_tenant,
        month: future_month,
        due_date: Date.new(future_month.year, future_month.month, 10)
      )
      payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 1000.00)

      calculator.update_all_missing_months

      # Should not create balance sheet for future month
      future_sheet = TenantBalanceSheet.find_by(property_tenant: property_tenant, month: future_month)
      expect(future_sheet).to be_nil
    end
  end
end
