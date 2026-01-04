# Currency configuration
# Set currency symbol and position (before or after the amount)
Rails.application.config.currency_symbol = ENV.fetch("CURRENCY_SYMBOL", "zł")
Rails.application.config.currency_position = ENV.fetch("CURRENCY_POSITION", "after") # "before" or "after"
Rails.application.config.currency_separator = ENV.fetch("CURRENCY_SEPARATOR", ",") # Decimal separator: "," or "."
