class UtilityProviderBalanceSheetCalculator
  def initialize(utility_provider)
    @utility_provider = utility_provider
    @property = utility_provider.property
  end

  def calculate_owed_for_month(month)
    month_begin = month.beginning_of_month
    month_end = month.end_of_month

    # Sum all forecast line items that are due in this month
    ForecastLineItem.joins(:forecast)
      .where(forecasts: {utility_provider_id: @utility_provider.id, property_id: @property.id})
      .where("forecast_line_items.due_date >= ? AND forecast_line_items.due_date <= ?", month_begin, month_end)
      .where("forecasts.issued_date <= ?", month_end)
      .sum(:amount)
  end

  def calculate_paid_for_month(month)
    month_begin = month.beginning_of_month
    month_end = month.end_of_month

    # Sum all utility payments where paid_date falls within the month
    @utility_provider.utility_payments
      .where("paid_date >= ? AND paid_date <= ?", month_begin, month_end)
      .sum(:amount)
  end

  def get_due_date_for_month(month)
    # Use the earliest forecast line item's due_date for the month
    month_begin = month.beginning_of_month
    month_end = month.end_of_month

    earliest_due_date = ForecastLineItem.joins(:forecast)
      .where(forecasts: {utility_provider_id: @utility_provider.id, property_id: @property.id})
      .where("forecast_line_items.due_date >= ? AND forecast_line_items.due_date <= ?", month_begin, month_end)
      .where("forecasts.issued_date <= ?", month_end)
      .minimum(:due_date)

    earliest_due_date || Date.new(month.year, month.month, 10)
  end

  def update_balance_sheet_for_month(month, allow_update: false)
    month_begin = month.beginning_of_month
    balance_sheet = @utility_provider.utility_provider_balance_sheets.find_by(month: month_begin)

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
      balance_sheet = @utility_provider.utility_provider_balance_sheets.create!(
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

    # Find all months that have forecasts or payments
    months_with_data = Set.new

    # Months with forecast line items
    ForecastLineItem.joins(:forecast)
      .where(forecasts: {utility_provider_id: @utility_provider.id, property_id: @property.id})
      .pluck(:due_date)
      .each do |due_date|
        months_with_data << due_date.beginning_of_month
      end

    # Months with payments
    @utility_provider.utility_payments.pluck(:paid_date).each do |paid_date|
      months_with_data << paid_date.beginning_of_month
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
