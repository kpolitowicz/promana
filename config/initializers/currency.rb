# Currency configuration
# Set currency symbol and position (before or after the amount)
Rails.application.config.currency_symbol = ENV.fetch("CURRENCY_SYMBOL", "$")
Rails.application.config.currency_position = ENV.fetch("CURRENCY_POSITION", "before") # "before" or "after"
