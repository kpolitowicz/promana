require "rails_helper"

RSpec.describe TenantBalanceSheetCalculator do
  fixtures :properties, :tenants, :property_tenants, :utility_providers

  let(:property) { properties(:property_one) }
  let(:property_tenant) { property_tenants(:property_tenant_one) }
  let(:calculator) { TenantBalanceSheetCalculator.new(property_tenant) }

  describe "#calculate_owed_for_month" do
    it "sums payslip total for the month" do
      month = Date.today.beginning_of_month
      payslip = Payslip.create!(
        property: property,
        property_tenant: property_tenant,
        month: month,
        due_date: Date.new(month.year, month.month, 10)
      )
      payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 1000.00)
      payslip.payslip_line_items.create!(name: "Utilities", amount: 250.00)

      owed = calculator.calculate_owed_for_month(month)
      expect(owed).to eq(1250.00)
    end

    it "includes late-arriving forecasts for the month" do
      month = Date.today.beginning_of_month
      payslip = Payslip.create!(
        property: property,
        property_tenant: property_tenant,
        month: month,
        due_date: Date.new(month.year, month.month, 10),
        created_at: Time.zone.parse("#{month.year}-#{month.month}-01")
      )
      payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 1000.00)

      # Create a forecast issued after the payslip was created
      utility_provider = utility_providers(:utility_provider_one)
      forecast = Forecast.create!(
        utility_provider: utility_provider,
        property: property,
        issued_date: Date.new(month.year, month.month, 15)
      )
      ForecastLineItem.create!(
        forecast: forecast,
        name: "Forecast",
        amount: 200.00,
        due_date: Date.new(month.year, month.month, 10)
      )

      owed = calculator.calculate_owed_for_month(month)
      expect(owed).to eq(1200.00) # 1000 from payslip + 200 from late forecast
    end

    it "returns 0 when no payslip or forecasts exist" do
      month = Date.today.beginning_of_month
      owed = calculator.calculate_owed_for_month(month)
      expect(owed).to eq(0.0)
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
      payslip = Payslip.create!(
        property: property,
        property_tenant: property_tenant,
        month: month,
        due_date: Date.new(month.year, month.month, 10)
      )
      payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 1000.00)

      TenantPayment.create!(
        property_tenant: property_tenant,
        property: property,
        amount: 800.00,
        paid_date: Date.new(month.year, month.month, 15)
      )

      balance_sheet = calculator.update_balance_sheet_for_month(month, allow_update: true)

      expect(balance_sheet).to be_persisted
      expect(balance_sheet.owed).to eq(1000.00)
      expect(balance_sheet.paid).to eq(800.00)
      expect(balance_sheet.balance).to eq(200.00)
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

      # Create new payslip and payment
      payslip = Payslip.create!(
        property: property,
        property_tenant: property_tenant,
        month: month,
        due_date: Date.new(month.year, month.month, 10)
      )
      payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 1200.00)

      TenantPayment.create!(
        property_tenant: property_tenant,
        property: property,
        amount: 1000.00,
        paid_date: Date.new(month.year, month.month, 15)
      )

      updated = calculator.update_balance_sheet_for_month(month, allow_update: true)

      expect(updated.id).to eq(balance_sheet.id)
      expect(updated.owed).to eq(1200.00)
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

      # Create new payslip and payment
      payslip = Payslip.create!(
        property: property,
        property_tenant: property_tenant,
        month: month,
        due_date: Date.new(month.year, month.month, 10)
      )
      payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 1500.00)

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

      payslip = Payslip.create!(
        property: property,
        property_tenant: property_tenant,
        month: january,
        due_date: Date.new(2025, 1, 10)
      )
      payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 1000.00)

      calculator.update_all_missing_months

      # Should create balance sheet for January (if not current month) and current month
      balance_sheets = TenantBalanceSheet.where(property_tenant: property_tenant)
      expect(balance_sheets.count).to be >= 1
      january_sheet = TenantBalanceSheet.find_by(property_tenant: property_tenant, month: january)
      if january != current_month
        expect(january_sheet).not_to be_nil
        expect(january_sheet.owed).to eq(1000.00)
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
  end
end
