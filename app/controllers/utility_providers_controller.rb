class UtilityProvidersController < ApplicationController
  before_action :set_property
  before_action :set_utility_provider, only: [:show, :edit, :update, :destroy]

  def index
    @utility_providers = @property.utility_providers.order(:name)
  end

  def show
  end

  def new
    @utility_provider = UtilityProvider.new(property: @property)
    @utility_types = UtilityType.all.order(:name)
  end

  def create
    @utility_provider = UtilityProvider.new(utility_provider_params)
    @utility_provider.property = @property

    if @utility_provider.save
      update_utility_types
      redirect_to property_utility_provider_path(@property, @utility_provider), notice: "Utility provider was successfully created."
    else
      @utility_types = UtilityType.all.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @utility_types = UtilityType.all.order(:name)
  end

  def update
    if @utility_provider.update(utility_provider_params)
      update_utility_types
      redirect_to property_utility_provider_path(@property, @utility_provider), notice: "Utility provider was successfully updated."
    else
      @utility_types = UtilityType.all.order(:name)
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @utility_provider.destroy
    redirect_to property_path(@property), notice: "Utility provider was successfully deleted."
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

  def set_utility_provider
    @utility_provider = @property.utility_providers.find(params[:id])
  end

  def utility_provider_params
    params.require(:utility_provider).permit(:name, :forecast_behavior)
  end

  def update_utility_types
    return unless params[:utility_provider][:utility_type_ids]

    selected_type_ids = params[:utility_provider][:utility_type_ids].reject(&:blank?).map(&:to_i)
    current_type_ids = @utility_provider.utility_type_ids

    # Remove unselected types
    (current_type_ids - selected_type_ids).each do |type_id|
      @utility_provider.utility_provider_utility_types.where(utility_type_id: type_id).destroy_all
    end

    # Add new types
    (selected_type_ids - current_type_ids).each do |type_id|
      @utility_provider.utility_provider_utility_types.create(utility_type_id: type_id)
    end
  end
end
