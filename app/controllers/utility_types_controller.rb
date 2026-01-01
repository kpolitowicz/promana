class UtilityTypesController < ApplicationController
  before_action :set_utility_type, only: [:destroy]

  def index
    @utility_types = UtilityType.all.order(:name)
  end

  def new
    @utility_type = UtilityType.new
  end

  def create
    @utility_type = UtilityType.new(utility_type_params)

    if @utility_type.save
      redirect_to utility_types_path, notice: "Utility type was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @utility_type.destroy
    redirect_to utility_types_path, notice: "Utility type was successfully deleted."
  end

  private

  def set_utility_type
    @utility_type = UtilityType.find(params[:id])
  end

  def utility_type_params
    params.require(:utility_type).permit(:name)
  end
end
