class PayslipGenerator
  def initialize(property_tenant, month: nil, due_date: nil)
    @property_tenant = property_tenant
    @property = property_tenant.property
    @month = month || Date.today.next_month.beginning_of_month
    @due_date = due_date || Date.new(@month.year, @month.month, 10)
  end

  def generate
    line_items = []

    # Add rent line item
    line_items << {
      name: Payslip.rent_label,
      amount: @property_tenant.rent_amount
    }

    # Add utility line items from each utility provider
    @property.utility_providers.each do |utility_provider|
      forecast_line_items = find_forecast_line_items(utility_provider, @month)
      forecast_line_items.each do |line_item|
        line_items << {
          name: "#{utility_provider.name} - #{line_item.name}",
          amount: line_item.amount
        }
      end
    end

    # Add payment difference from previous month if applicable
    payment_diff = calculate_payment_difference
    if payment_diff && payment_diff[:amount] != 0
      line_items << {
        name: payment_diff[:label],
        amount: payment_diff[:amount]
      }
    end

    # Add forecast adjustment from previous month if applicable
    forecast_adjustment = calculate_forecast_adjustment
    if forecast_adjustment && forecast_adjustment[:amount] != 0
      line_items << {
        name: forecast_adjustment[:label],
        amount: forecast_adjustment[:amount]
      }
    end

    {
      property: @property,
      property_tenant: @property_tenant,
      month: @month,
      due_date: @due_date,
      line_items: line_items
    }
  end

  private

  def find_forecast_line_items(utility_provider, target_month)
    # Find all forecast line items that have due_date in the target month
    active_line_items = ForecastLineItem.joins(:forecast)
      .where(forecasts: {utility_provider_id: utility_provider.id})
      .where("forecast_line_items.due_date >= ? AND forecast_line_items.due_date < ?",
        target_month.beginning_of_month,
        target_month.next_month.beginning_of_month)

    if active_line_items.any?
      active_line_items
    else
      last_forecast = find_last_forecast(utility_provider, target_month)
      last_forecast ? last_forecast.forecast_line_items.where(carry_forward: true) : ForecastLineItem.none
    end
  end

  def find_last_forecast(utility_provider, target_month)
    # Find the most recent forecast with line items before the target month
    utility_provider.forecasts.joins(:forecast_line_items)
      .where("forecast_line_items.due_date < ?", target_month.beginning_of_month)
      .distinct
      .order(issued_date: :desc)
      .first
  end

  def calculate_payment_difference
    previous_month = @month - 1.month
    previous_payslip = @property_tenant.payslips.find_by(month: previous_month.beginning_of_month)

    return nil unless previous_payslip

    # Find payments made in the previous month (paid_date falls within that month)
    payments_in_month = @property_tenant.tenant_payments.where(
      "paid_date >= ? AND paid_date < ?",
      previous_month.beginning_of_month,
      previous_month.next_month.beginning_of_month
    )

    total_paid = payments_in_month.sum(:amount)
    payslip_total = previous_payslip.total_amount
    difference = total_paid - payslip_total

    return nil if difference == 0

    if difference > 0
      # Overpayment - negative amount (credit to tenant)
      {
        label: Payslip.overpayment_label,
        amount: -difference
      }
    else
      # Underpayment - positive amount (debt owed)
      {
        label: Payslip.underpayment_label,
        amount: -difference # difference is negative, so negate it to get positive
      }
    end
  end

  def calculate_forecast_adjustment
    previous_month = @month - 1.month
    previous_payslip = @property_tenant.payslips.find_by(month: previous_month.beginning_of_month)

    return nil unless previous_payslip

    total_adjustment = 0.0

    # For each utility provider, calculate the adjustment
    @property.utility_providers.each do |utility_provider|
      # Find what was included in the previous payslip for this provider
      payslip_amounts = extract_payslip_amounts_for_provider(previous_payslip, utility_provider)

      # Find the most recent forecast for the previous month (issued after payslip was created or most recent)
      current_forecast = find_current_forecast_for_month(utility_provider, previous_month, previous_payslip.created_at)

      next unless current_forecast

      # Find forecast line items for the previous month
      forecast_line_items = current_forecast.forecast_line_items.where(
        "due_date >= ? AND due_date < ?",
        previous_month.beginning_of_month,
        previous_month.next_month.beginning_of_month
      )

      # Calculate difference for each line item
      forecast_line_items.each do |forecast_line_item|
        payslip_amount = payslip_amounts[forecast_line_item.name] || 0.0
        difference = forecast_line_item.amount - payslip_amount
        total_adjustment += difference
      end
    end

    return nil if total_adjustment == 0

    {
      label: Payslip.adjustment_label,
      amount: total_adjustment
    }
  end

  def extract_payslip_amounts_for_provider(payslip, utility_provider)
    # Extract amounts from payslip line items that match this utility provider
    # Line items have format: "Provider Name - Line Item Name"
    amounts = {}
    provider_prefix = "#{utility_provider.name} - "

    payslip.payslip_line_items.each do |line_item|
      if line_item.name.start_with?(provider_prefix)
        line_item_name = line_item.name.sub(provider_prefix, "")
        amounts[line_item_name] = line_item.amount
      end
    end

    amounts
  end

  def find_current_forecast_for_month(utility_provider, target_month, payslip_created_at)
    # Find the most recent forecast for the target month
    # Prefer forecasts issued after the payslip was created, but fall back to most recent
    forecasts = utility_provider.forecasts.joins(:forecast_line_items)
      .where("forecast_line_items.due_date >= ? AND forecast_line_items.due_date < ?",
        target_month.beginning_of_month,
        target_month.next_month.beginning_of_month)
      .distinct

    # Prefer forecast issued after payslip was created
    forecast_after_payslip = forecasts.where("forecasts.issued_date > ?", payslip_created_at)
      .order(issued_date: :desc)
      .first

    return forecast_after_payslip if forecast_after_payslip

    # Fall back to most recent forecast for that month
    forecasts.order(issued_date: :desc).first
  end
end
