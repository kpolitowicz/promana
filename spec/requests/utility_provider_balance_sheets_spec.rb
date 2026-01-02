require "rails_helper"

RSpec.describe "UtilityProviderBalanceSheets", type: :request do
  fixtures :properties, :utility_providers

  let(:property) { properties(:property_one) }
  let(:utility_provider) { utility_providers(:utility_provider_one) }

  describe "GET /properties/:property_id/utility_providers/:utility_provider_id/utility_provider_balance_sheets" do
    it "returns http success" do
      get property_utility_provider_utility_provider_balance_sheets_path(property, utility_provider)
      expect(response).to have_http_status(:success)
    end

    it "displays balance sheets ordered by due_date descending" do
      UtilityProviderBalanceSheet.create!(
        utility_provider: utility_provider,
        property: property,
        month: Date.new(2026, 1, 1),
        due_date: Date.new(2026, 1, 10),
        owed: 500.00,
        paid: 500.00
      )

      get property_utility_provider_utility_provider_balance_sheets_path(property, utility_provider)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("January 2026")
    end
  end

  describe "PATCH /properties/:property_id/utility_providers/:utility_provider_id/utility_provider_balance_sheets/update_all" do
    it "updates balance sheets and redirects" do
      month = Date.today.beginning_of_month
      forecast = Forecast.create!(
        utility_provider: utility_provider,
        property: property,
        issued_date: month
      )
      ForecastLineItem.create!(
        forecast: forecast,
        name: "Forecast",
        amount: 300.00,
        due_date: Date.new(month.year, month.month, 10)
      )

      patch update_all_property_utility_provider_utility_provider_balance_sheets_path(property, utility_provider)
      expect(response).to redirect_to(property_utility_provider_utility_provider_balance_sheets_path(property, utility_provider))
      expect(UtilityProviderBalanceSheet.where(utility_provider: utility_provider).count).to eq(1)
    end
  end
end
