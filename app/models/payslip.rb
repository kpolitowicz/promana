class Payslip < ApplicationRecord
  belongs_to :property
  belongs_to :property_tenant
  has_many :payslip_line_items, dependent: :destroy

  accepts_nested_attributes_for :payslip_line_items, allow_destroy: true

  validates :month, presence: true
  validates :due_date, presence: true
  validates :property_id, uniqueness: {scope: [:property_tenant_id, :month]}

  def total_amount
    payslip_line_items.sum(:amount)
  end

  def tenant
    property_tenant.tenant
  end

  # Configurable header labels for payslip display
  def self.name_header
    "Pozycja"
  end

  def self.amount_header
    "Kwota"
  end

  def self.total_header
    "Razem"
  end

  # Configurable labels for payment differences
  def self.underpayment_label
    "Zaległe"
  end

  def self.overpayment_label
    "Nadpłata"
  end

  # Configurable label for forecast adjustments
  def self.adjustment_label
    "Wyrównanie"
  end

  # Configurable label for rent
  def self.rent_label
    "Czynsz"
  end

  def rent_amount
    payslip_line_items.find_by(name: Payslip.rent_label)&.amount
  end

  # Generate ASCII text format of payslip for clipboard copying
  def to_ascii_text(property, tenant)
    lines = []
    separator = Rails.application.config.currency_separator
    symbol = Rails.application.config.currency_symbol
    position = Rails.application.config.currency_position

    # Calculate column widths based on content
    name_col_width = [Payslip.name_header.length, Payslip.total_header.length, *payslip_line_items.map { |li| li.name.length }].max
    name_col_width = [name_col_width, 20].max # Minimum width

    # Calculate amount column width based on formatted amounts
    amount_strings = payslip_line_items.map { |li| format_currency_for_ascii(li.amount, separator, symbol, position) }
    amount_strings << format_currency_for_ascii(total_amount, separator, symbol, position)
    amount_strings << Payslip.amount_header
    amount_col_width = amount_strings.map(&:length).max

    # Table header
    lines << "┌" + "-" * (name_col_width + 2) + "┬" + "-" * (amount_col_width + 2) + "┐"
    lines << "│ #{Payslip.name_header.ljust(name_col_width)} │ #{Payslip.amount_header.rjust(amount_col_width)} │"
    lines << "├" + "-" * (name_col_width + 2) + "┼" + "-" * (amount_col_width + 2) + "┤"

    # Line items
    payslip_line_items.each do |line_item|
      name = line_item.name.ljust(name_col_width)
      amount_str = format_currency_for_ascii(line_item.amount, separator, symbol, position)
      amount_str = amount_str.rjust(amount_col_width)
      lines << "│ #{name} │ #{amount_str} │"
    end

    # Total row
    lines << "├" + "-" * (name_col_width + 2) + "┼" + "-" * (amount_col_width + 2) + "┤"
    total_str = format_currency_for_ascii(total_amount, separator, symbol, position)
    total_str = total_str.rjust(amount_col_width)
    lines << "│ #{Payslip.total_header.ljust(name_col_width)} │ #{total_str} │"
    lines << "└" + "-" * (name_col_width + 2) + "┴" + "-" * (amount_col_width + 2) + "┘"

    lines.join("\n")
  end

  private

  def format_currency_for_ascii(amount, separator, symbol, position)
    # Format number with 2 decimal places
    formatted = sprintf("%.2f", amount)
    formatted = formatted.gsub(".", separator)

    case position
    when "after"
      "#{formatted} #{symbol}"
    else
      "#{symbol}#{formatted}"
    end
  end
end
