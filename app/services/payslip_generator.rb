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
      forecast_line_items = find_forecast_line_items(utility_provider, @month)
      forecast_line_items.each do |line_item|
        line_items << {
          name: "#{utility_provider.name} - #{line_item.name}",
          amount: line_item.amount
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
      # No active forecast line items - apply forecast behavior
      case utility_provider.forecast_behavior
      when "zero_after_expiry"
        ForecastLineItem.none
      when "carry_forward"
        # Find the most recent forecast before the target month
        last_forecast = find_last_forecast(utility_provider, target_month)
        if last_forecast
          last_forecast.forecast_line_items
        else
          ForecastLineItem.none
        end
      else
        ForecastLineItem.none
      end
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
end
