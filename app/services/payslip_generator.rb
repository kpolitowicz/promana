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
      name: "Rent",
      amount: @property_tenant.rent_amount
    }

    # Add utility line items from each utility provider
    @property.utility_providers.each do |utility_provider|
      utility_amount = calculate_utility_amount(utility_provider, @month)
      if utility_amount != 0
        line_items << {
          name: utility_provider.name,
          amount: utility_amount
        }
      end
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

  def calculate_utility_amount(utility_provider, target_month)
    # Find forecasts with line items that have due_date in the target month
    active_forecast = find_active_forecast(utility_provider, target_month)

    if active_forecast
      # Sum all line items from the active forecast
      active_forecast.forecast_line_items.sum(:amount)
    else
      # No active forecast - apply forecast behavior
      case utility_provider.forecast_behavior
      when "zero_after_expiry"
        0
      when "carry_forward"
        # Find the most recent forecast before the target month
        last_forecast = find_last_forecast(utility_provider, target_month)
        if last_forecast
          last_forecast.forecast_line_items.sum(:amount)
        else
          0
        end
      else
        0
      end
    end
  end

  def find_active_forecast(utility_provider, target_month)
    # Find forecasts where at least one line item's due_date falls in the target month
    utility_provider.forecasts.joins(:forecast_line_items)
      .where("forecast_line_items.due_date >= ? AND forecast_line_items.due_date < ?",
        target_month.beginning_of_month,
        target_month.next_month.beginning_of_month)
      .distinct
      .order(issued_date: :desc)
      .first
  end

  def find_last_forecast(utility_provider, target_month)
    # Find the most recent forecast with line items before the target month
    utility_provider.forecasts.joins(:forecast_line_items)
      .where("forecast_line_items.due_date < ?", target_month.beginning_of_month)
      .distinct
      .order(issued_date: :desc)
      .first
  end
end
