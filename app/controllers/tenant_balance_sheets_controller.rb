class TenantBalanceSheetsController < ApplicationController
  before_action :set_property_tenant

  def index
    @balance_sheets = @property_tenant.tenant_balance_sheets.order(due_date: :desc)
    @current_balance = @balance_sheets.sum { |bs| bs.balance }
  end

  def update_all
    calculator = TenantBalanceSheetCalculator.new(@property_tenant)
    calculator.update_all_missing_months
    redirect_to property_property_tenant_tenant_balance_sheets_path(@property, @property_tenant), notice: "Balance sheet updated successfully."
  end

  private

  def set_property_tenant
    @property = Property.find(params[:property_id])
    @property_tenant = @property.property_tenants.find(params[:property_tenant_id])
  end
end
