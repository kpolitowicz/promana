class TenantBalanceSheetCalculator
  def initialize(property_tenant)
    @property_tenant = property_tenant
    @property = property_tenant.property
  end

  def calculate_owed_for_month(month)
    month_begin = month.beginning_of_month
    month_end = month.end_of_month

    # Sum all payslip line items for payslips in this month
    payslip = @property_tenant.payslips.find_by(month: month_begin)
    payslip_total = payslip ? payslip.total_amount : 0.0

    # Also include forecast line items that are due in this month
    # This handles the edge case where forecasts come late (after payslip was generated)
    # Include forecasts issued after the payslip was created (or all if no payslip)
    forecast_total = 0.0
    @property.utility_providers.each do |utility_provider|
      query = ForecastLineItem.joins(:forecast)
        .where(forecasts: {utility_provider_id: utility_provider.id, property_id: @property.id})
        .where("forecast_line_items.due_date >= ? AND forecast_line_items.due_date <= ?", month_begin, month_end)

      # If payslip exists, only include forecasts issued after it was created
      if payslip
        query = query.where("forecasts.issued_date > ?", payslip.created_at)
      else
        # If no payslip, include all forecasts issued before end of month
        query = query.where("forecasts.issued_date <= ?", month_end)
      end

      forecast_total += query.sum(:amount)
    end

    payslip_total + forecast_total
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

    # Find all months that have payslips or payments
    months_with_data = Set.new

    # Months with payslips
    @property_tenant.payslips.pluck(:month).each do |month|
      months_with_data << month.beginning_of_month
    end

    # Months with payments
    @property_tenant.tenant_payments.pluck(:paid_date).each do |paid_date|
      months_with_data << paid_date.beginning_of_month
    end

    # Months with forecasts (for late-arriving forecasts)
    @property.utility_providers.each do |utility_provider|
      ForecastLineItem.joins(:forecast)
        .where(forecasts: {utility_provider_id: utility_provider.id, property_id: @property.id})
        .pluck(:due_date)
        .each do |due_date|
          months_with_data << due_date.beginning_of_month
        end
    end

    # Update current month (allow updates)
    update_balance_sheet_for_month(current_month, allow_update: true)

    # Add missing months (don't allow updates for past months)
    months_with_data.each do |month|
      month_begin = month.beginning_of_month
      next if month_begin == current_month # Already handled above

      update_balance_sheet_for_month(month_begin, allow_update: false)
    end
  end
end
