module ApplicationHelper
  def format_currency(amount, precision: 2)
    separator = Rails.application.config.currency_separator
    formatted_amount = number_with_precision(amount, precision: precision, separator: separator, delimiter: "")
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
