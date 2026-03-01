class TenantBalanceSheetCalculator
  def initialize(property_tenant)
    @property_tenant = property_tenant
    @property = property_tenant.property
  end

  def calculate_owed_for_month(month)
    month_begin = month.beginning_of_month
    month_end = month.end_of_month

    # Find the rent owed on month's payslip or use the current rent amount
    payslip = @property_tenant.payslips.find_by(month: month_begin)
    rent_total = payslip ? payslip.rent_amount : @property_tenant.rent_amount

    forecast_total = 0.0
    @property.utility_providers.each do |utility_provider|
      total = ForecastLineItem.joins(:forecast)
        .where(forecasts: {utility_provider_id: utility_provider.id, property_id: @property.id})
        .where("forecast_line_items.due_date >= ? AND forecast_line_items.due_date <= ?", month_begin, month_end)
        .sum(:amount)
      if total.zero?
        last_cf_date = ForecastLineItem.joins(:forecast)
          .where(forecasts: {utility_provider_id: utility_provider.id, property_id: @property.id})
          .where(carry_forward: true)
          .maximum("forecast_line_items.due_date")
        next unless last_cf_date

        total = ForecastLineItem.joins(:forecast)
          .where(forecasts: {utility_provider_id: utility_provider.id, property_id: @property.id})
          .where(carry_forward: true)
          .where("forecast_line_items.due_date >= ? AND forecast_line_items.due_date <= ?", last_cf_date.beginning_of_month, last_cf_date.end_of_month)
          .sum(:amount)
      end

      forecast_total += total
    end

    rent_total + forecast_total
  end

  def calculate_paid_for_month(month)
    month_begin = month.beginning_of_month
    month_end = month.end_of_month

    # Sum all tenant payments where paid_date falls within the month
    @property_tenant.tenant_payments
      .where("paid_date >= ? AND paid_date <= ?", month_begin, month_end)
      .sum(:amount)
  end

  def get_due_date_for_month(month)
    # Use the payslip's due_date if it exists, otherwise use the 10th of the month
    payslip = @property_tenant.payslips.find_by(month: month.beginning_of_month)
    if payslip
      payslip.due_date
    else
      Date.new(month.year, month.month, 10)
    end
  end

  def update_balance_sheet_for_month(month, allow_update: false)
    month_begin = month.beginning_of_month
    balance_sheet = @property_tenant.tenant_balance_sheets.find_by(month: month_begin)

    if balance_sheet && !allow_update
      # Don't update existing balance sheets for past months
      return balance_sheet
    end

    owed = calculate_owed_for_month(month_begin)
    paid = calculate_paid_for_month(month_begin)
    due_date = get_due_date_for_month(month_begin)

    if balance_sheet
      balance_sheet.update!(
        owed: owed,
        paid: paid,
        due_date: due_date
      )
    else
      balance_sheet = @property_tenant.tenant_balance_sheets.create!(
        property: @property,
        month: month_begin,
        due_date: due_date,
        owed: owed,
        paid: paid
      )
    end

    balance_sheet
  end

  def update_all_missing_months
    current_month = Date.today.beginning_of_month

    # Find all months that have payslips or payments (only past and current months)
    months_with_data = Set.new

    # Months with payslips (only past and current)
    @property_tenant.payslips.pluck(:month).each do |month|
      month_begin = month.beginning_of_month
      months_with_data << month_begin if month_begin <= current_month
    end

    # Months with payments (only past and current)
    @property_tenant.tenant_payments.pluck(:paid_date).each do |paid_date|
      month_begin = paid_date.beginning_of_month
      months_with_data << month_begin if month_begin <= current_month
    end

    # Months with forecasts (for late-arriving forecasts, only past and current)
    @property.utility_providers.each do |utility_provider|
      ForecastLineItem.joins(:forecast)
        .where(forecasts: {utility_provider_id: utility_provider.id, property_id: @property.id})
        .pluck(:due_date)
        .each do |due_date|
          month_begin = due_date.beginning_of_month
          months_with_data << month_begin if month_begin <= current_month
        end
    end

    # Update current month (allow updates)
    update_balance_sheet_for_month(current_month, allow_update: true)

    # Add missing months (don't allow updates for past months, never create future months)
    months_with_data.each do |month|
      month_begin = month.beginning_of_month
      next if month_begin == current_month # Already handled above
      next if month_begin > current_month # Never create future months

      update_balance_sheet_for_month(month_begin, allow_update: false)
    end
  end
end
