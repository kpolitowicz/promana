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
    payslip_data = generator.generate

    @payslip = Payslip.new(month: month, due_date: due_date)
    # Build line items from generated data
    payslip_data[:line_items].each do |line_item|
      @payslip.payslip_line_items.build(name: line_item[:name], amount: line_item[:amount])
    end
  end

  def create
    @payslip = @property_tenant.payslips.build(payslip_params)

    # Ensure month is beginning of month for uniqueness validation
    if @payslip.month.present?
      @payslip.month = @payslip.month.beginning_of_month
    end

    if @payslip.save
      redirect_to property_property_tenant_payslip_path(@property, @property_tenant, @payslip), notice: "Payslip was successfully created."
    else
      # If validation fails, rebuild line items from generator
      month = @payslip.month || Date.today.next_month.beginning_of_month
      due_date = @payslip.due_date || Date.new(month.year, month.month, 10)
      generator = PayslipGenerator.new(@property_tenant, month: month, due_date: due_date)
      payslip_data = generator.generate

      # Rebuild line items if they were lost
      if @payslip.payslip_line_items.empty?
        payslip_data[:line_items].each do |line_item|
          @payslip.payslip_line_items.build(name: line_item[:name], amount: line_item[:amount])
        end
      end

      render :new, status: :unprocessable_content
    end
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
    params.require(:payslip).permit(:month, :due_date, payslip_line_items_attributes: [:id, :name, :amount, :_destroy])
  end
end
