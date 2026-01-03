class PropertiesController < ApplicationController
  before_action :set_property, only: [:show]

  def index
    @properties = Property.all.order(:name)
  end

  def show
    @property_tenants = @property.property_tenants.includes(:tenant).order("tenants.name")
  end

  private

  def set_property
    @property = Property.find(params[:id])
  end
end
