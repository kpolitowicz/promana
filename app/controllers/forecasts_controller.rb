class ForecastsController < ApplicationController
  before_action :set_property
  before_action :set_utility_provider
  before_action :set_forecast, only: [:show, :edit, :update, :destroy]

  def index
    @forecasts = @utility_provider.forecasts.order(issued_date: :desc)
  end

  def show
  end

  def new
    @forecast = Forecast.new(utility_provider: @utility_provider, property: @property, issued_date: Date.today)
    @forecast.forecast_line_items.build
  end

  def create
    @forecast = Forecast.new(forecast_params)
    @forecast.utility_provider = @utility_provider
    @forecast.property = @property

    if @forecast.save
      redirect_to property_utility_provider_forecast_path(@property, @utility_provider, @forecast), notice: "Forecast was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @forecast.update(forecast_params)
      redirect_to property_utility_provider_forecast_path(@property, @utility_provider, @forecast), notice: "Forecast was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @forecast.destroy
    redirect_to property_utility_provider_forecasts_path(@property, @utility_provider), notice: "Forecast was successfully deleted."
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

  def set_utility_provider
    @utility_provider = @property.utility_providers.find(params[:utility_provider_id])
  end

  def set_forecast
    @forecast = @utility_provider.forecasts.find(params[:id])
  end

  def forecast_params
    params.require(:forecast).permit(:issued_date, forecast_line_items_attributes: [:id, :name, :amount, :due_date, :_destroy])
  end
end
