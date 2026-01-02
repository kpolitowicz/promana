class TenantPaymentsController < ApplicationController
  before_action :set_property
  before_action :set_property_tenant
  before_action :set_tenant_payment, only: [:show, :edit, :update, :destroy]

  def index
    @tenant_payments = @property_tenant.tenant_payments.order(paid_date: :desc)
  end

  def show
  end

  def new
    @tenant_payment = TenantPayment.new(property_tenant: @property_tenant, property: @property, paid_date: Date.today)
  end

  def create
    @tenant_payment = TenantPayment.new(tenant_payment_params)
    @tenant_payment.property_tenant = @property_tenant
    @tenant_payment.property = @property

    if @tenant_payment.save
      redirect_to property_property_tenant_tenant_payment_path(@property, @property_tenant, @tenant_payment), notice: "Payment was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @tenant_payment.update(tenant_payment_params)
      redirect_to property_property_tenant_tenant_payment_path(@property, @property_tenant, @tenant_payment), notice: "Payment was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @tenant_payment.destroy
    redirect_to property_property_tenant_tenant_payments_path(@property, @property_tenant), notice: "Payment was successfully deleted."
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

  def set_property_tenant
    @property_tenant = @property.property_tenants.find(params[:property_tenant_id])
  end

  def set_tenant_payment
    @tenant_payment = @property_tenant.tenant_payments.find(params[:id])
  end

  def tenant_payment_params
    params.require(:tenant_payment).permit(:amount, :paid_date)
  end
end
