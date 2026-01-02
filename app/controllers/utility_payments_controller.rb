class UtilityPaymentsController < ApplicationController
  before_action :set_property
  before_action :set_utility_provider
  before_action :set_utility_payment, only: [:show, :edit, :update, :destroy]

  def index
    @utility_payments = @utility_provider.utility_payments.order(paid_date: :desc)
  end

  def show
  end

  def new
    @utility_payment = UtilityPayment.new(utility_provider: @utility_provider, property: @property, paid_date: Date.today)
  end

  def create
    @utility_payment = UtilityPayment.new(utility_payment_params)
    @utility_payment.utility_provider = @utility_provider
    @utility_payment.property = @property

    if @utility_payment.save
      redirect_to property_utility_provider_utility_payment_path(@property, @utility_provider, @utility_payment), notice: "Payment was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @utility_payment.update(utility_payment_params)
      redirect_to property_utility_provider_utility_payment_path(@property, @utility_provider, @utility_payment), notice: "Payment was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @utility_payment.destroy
    redirect_to property_utility_provider_utility_payments_path(@property, @utility_provider), notice: "Payment was successfully deleted."
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

  def set_utility_provider
    @utility_provider = @property.utility_providers.find(params[:utility_provider_id])
  end

  def set_utility_payment
    @utility_payment = @utility_provider.utility_payments.find(params[:id])
  end

  def utility_payment_params
    params.require(:utility_payment).permit(:amount, :paid_date)
  end
end
