module ApplicationHelper
  def format_currency(amount, precision: 2)
    separator = Rails.application.config.currency_separator
    # Format with sprintf to ensure we control the decimal separator
    formatted_amount = sprintf("%.#{precision}f", amount)
    # Replace the default decimal point with our configured separator
    formatted_amount = formatted_amount.gsub(".", separator)
    symbol = Rails.application.config.currency_symbol
    position = Rails.application.config.currency_position

    case position
    when "after"
      "#{formatted_amount} #{symbol}"
    else # "before" (default)
      "#{symbol}#{formatted_amount}"
    end
  end
end
