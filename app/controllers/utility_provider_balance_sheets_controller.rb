class UtilityProviderBalanceSheetsController < ApplicationController
  before_action :set_utility_provider

  def index
    @balance_sheets = @utility_provider.utility_provider_balance_sheets.order(due_date: :desc)
    @current_balance = @balance_sheets.sum { |bs| bs.balance }
  end

  def update_all
    calculator = UtilityProviderBalanceSheetCalculator.new(@utility_provider)
    calculator.update_all_missing_months
    redirect_to property_utility_provider_utility_provider_balance_sheets_path(@property, @utility_provider), notice: "Balance sheet updated successfully."
  end

  private

  def set_utility_provider
    @property = Property.find(params[:property_id])
    @utility_provider = @property.utility_providers.find(params[:utility_provider_id])
  end
end
