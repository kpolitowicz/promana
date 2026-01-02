class PayslipsController < ApplicationController
  before_action :set_property_tenant
  before_action :set_payslip, only: [:show, :destroy]

  def index
    @payslips = @property_tenant.payslips.order(month: :desc)
  end

  def new
    month = params[:month].present? ? Date.parse(params[:month]) : Date.today.next_month.beginning_of_month
    due_date = params[:due_date].present? ? Date.parse(params[:due_date]) : Date.new(month.year, month.month, 10)

    generator = PayslipGenerator.new(@property_tenant, month: month, due_date: due_date)
    @payslip_data = generator.generate
    @payslip = Payslip.new(month: month, due_date: due_date)
  end

  def create
    @payslip = @property_tenant.payslips.build(payslip_params)

    if @payslip.save
      # Create line items
      items = line_items_params
      items.each do |item_params|
        @payslip.payslip_line_items.create!(item_params)
      end

      redirect_to property_property_tenant_payslip_path(@property, @property_tenant, @payslip), notice: "Payslip was successfully created."
    else
      # Regenerate payslip data for display
      month = @payslip.month || Date.today.next_month.beginning_of_month
      due_date = @payslip.due_date || Date.new(month.year, month.month, 10)
      generator = PayslipGenerator.new(@property_tenant, month: month, due_date: due_date)
      @payslip_data = generator.generate
      render :new, status: :unprocessable_content
    end
  rescue ActionController::ParameterMissing
    # Handle missing line_items parameter
    month = @payslip&.month || Date.today.next_month.beginning_of_month
    due_date = @payslip&.due_date || Date.new(month.year, month.month, 10)
    generator = PayslipGenerator.new(@property_tenant, month: month, due_date: due_date)
    @payslip_data = generator.generate
    @payslip ||= Payslip.new(month: month, due_date: due_date)
    @payslip.errors.add(:base, "Line items are required")
    render :new, status: :unprocessable_content
  end

  def show
  end

  def destroy
    @payslip.destroy
    redirect_to property_property_tenant_payslips_path(@property, @property_tenant), notice: "Payslip was successfully deleted."
  end

  private

  def set_property_tenant
    @property_tenant = PropertyTenant.find(params[:property_tenant_id])
    @property = @property_tenant.property
  end

  def set_payslip
    @payslip = @property_tenant.payslips.find(params[:id])
  end

  def payslip_params
    params.require(:payslip).permit(:month, :due_date)
  end

  def line_items_params
    return [] unless params[:line_items].present?
    params[:line_items].map do |item|
      if item.is_a?(ActionController::Parameters)
        item.permit(:name, :amount)
      else
        ActionController::Parameters.new(item).permit(:name, :amount)
      end
    end.reject { |item| item[:name].blank? || item[:amount].blank? }
  end
end
