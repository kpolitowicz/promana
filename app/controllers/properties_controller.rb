class PropertiesController < ApplicationController
  before_action :set_property, only: [:show, :edit, :update, :destroy]

  def index
    @properties = Property.all.order(:name)
  end

  def show
    @property_tenants = @property.property_tenants.includes(:tenant).order("tenants.name")
  end

  def new
    @property = Property.new
  end

  def create
    @property = Property.new(property_params)

    if @property.save
      redirect_to @property, notice: "Property was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @property.update(property_params)
      redirect_to @property, notice: "Property was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @property.destroy
    redirect_to properties_url, notice: "Property was successfully deleted."
  end

  private

  def set_property
    @property = Property.find(params[:id])
  end

  def property_params
    params.require(:property).permit(:name, :address)
  end
end
