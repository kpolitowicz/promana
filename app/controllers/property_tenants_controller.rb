class PropertyTenantsController < ApplicationController
  before_action :set_property
  before_action :set_property_tenant, only: [:destroy]

  def new
    @property_tenant = PropertyTenant.new(property: @property)
    @available_tenants = Tenant.where.not(id: @property.tenant_ids).order(:name)
  end

  def create
    @property_tenant = PropertyTenant.new(property_tenant_params)
    @property_tenant.property = @property

    if @property_tenant.save
      redirect_to property_setting_path(@property), notice: "Tenant was successfully assigned to property."
    else
      @available_tenants = Tenant.where.not(id: @property.tenant_ids).order(:name)
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @property_tenant.destroy
    redirect_to property_setting_path(@property), notice: "Tenant was successfully removed from property."
  end

  private

  def set_property
    property_id = params[:property_id] || params[:property_setting_id]
    @property = Property.find(property_id)
  end

  def set_property_tenant
    @property_tenant = @property.property_tenants.find(params[:id])
  end

  def property_tenant_params
    params.require(:property_tenant).permit(:tenant_id, :rent_amount)
  end
end
