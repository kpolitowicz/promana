require "rails_helper"

RSpec.describe "Forecasts", type: :request do
  fixtures :properties, :utility_providers

  let(:property) { properties(:property_one) }
  let(:utility_provider) { utility_providers(:utility_provider_one) }

  describe "GET /properties/:property_id/utility_providers/:utility_provider_id/forecasts/new" do
    it "renders the new template" do
      get new_property_utility_provider_forecast_path(property, utility_provider)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /properties/:property_id/utility_providers/:utility_provider_id/forecasts" do
    context "with valid parameters" do
      it "creates a new forecast" do
        expect {
          post property_utility_provider_forecasts_path(property, utility_provider), params: {
            forecast: {
              issued_date: Date.today,
              forecast_line_items_attributes: [
                {name: "Forecast", amount: 100.50, due_date: Date.today + 30.days},
                {name: "Rozliczenie", amount: 50.25, due_date: Date.today + 60.days}
              ]
            }
          }
        }.to change(Forecast, :count).by(1)
      end

      it "creates forecast line items" do
        post property_utility_provider_forecasts_path(property, utility_provider), params: {
          forecast: {
            issued_date: Date.today,
            forecast_line_items_attributes: [
              {name: "Forecast", amount: 100.50, due_date: Date.today + 30.days}
            ]
          }
        }
        forecast = Forecast.last
        expect(forecast.forecast_line_items.count).to eq(1)
        expect(forecast.forecast_line_items.first.name).to eq("Forecast")
      end

      it "redirects to the forecast show page" do
        post property_utility_provider_forecasts_path(property, utility_provider), params: {
          forecast: {
            issued_date: Date.today,
            forecast_line_items_attributes: [
              {name: "Forecast", amount: 100.50, due_date: Date.today + 30.days}
            ]
          }
        }
        forecast = Forecast.last
        expect(response).to redirect_to(property_utility_provider_forecast_path(property, utility_provider, forecast))
      end
    end

    context "with invalid parameters" do
      it "does not create a forecast without issued_date" do
        expect {
          post property_utility_provider_forecasts_path(property, utility_provider), params: {
            forecast: {
              forecast_line_items_attributes: [
                {name: "Forecast", amount: 100.50, due_date: Date.today + 30.days}
              ]
            }
          }
        }.not_to change(Forecast, :count)
      end

      it "renders the new template with errors" do
        post property_utility_provider_forecasts_path(property, utility_provider), params: {
          forecast: {
            forecast_line_items_attributes: [
              {name: "Forecast", amount: 100.50, due_date: Date.today + 30.days}
            ]
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create forecast with invalid line items" do
        expect {
          post property_utility_provider_forecasts_path(property, utility_provider), params: {
            forecast: {
              issued_date: Date.today,
              forecast_line_items_attributes: [
                {name: "", amount: 100.50, due_date: Date.today + 30.days}
              ]
            }
          }
        }.not_to change(Forecast, :count)
      end
    end
  end

  describe "GET /properties/:property_id/utility_providers/:utility_provider_id/forecasts/:id" do
    let(:forecast) do
      Forecast.create!(
        utility_provider: utility_provider,
        property: property,
        issued_date: Date.today,
        forecast_line_items_attributes: [
          {name: "Forecast", amount: 100.50, due_date: Date.today + 30.days}
        ]
      )
    end

    it "renders the show template" do
      get property_utility_provider_forecast_path(property, utility_provider, forecast)
      expect(response).to have_http_status(:success)
    end

    it "displays forecast information" do
      get property_utility_provider_forecast_path(property, utility_provider, forecast)
      expect(response.body).to include("Forecast")
      expect(response.body).to include("100.50")
    end
  end

  describe "GET /properties/:property_id/utility_providers/:utility_provider_id/forecasts/:id/edit" do
    let(:forecast) do
      Forecast.create!(
        utility_provider: utility_provider,
        property: property,
        issued_date: Date.today
      )
    end

    it "renders the edit template" do
      get edit_property_utility_provider_forecast_path(property, utility_provider, forecast)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /properties/:property_id/utility_providers/:utility_provider_id/forecasts/:id" do
    let(:forecast) do
      Forecast.create!(
        utility_provider: utility_provider,
        property: property,
        issued_date: Date.today,
        forecast_line_items_attributes: [
          {name: "Forecast", amount: 100.50, due_date: Date.today + 30.days}
        ]
      )
    end

    context "with valid parameters" do
      it "updates the forecast" do
        new_date = Date.today + 1.day
        patch property_utility_provider_forecast_path(property, utility_provider, forecast), params: {
          forecast: {
            issued_date: new_date
          }
        }
        forecast.reload
        expect(forecast.issued_date).to eq(new_date)
      end

      it "updates forecast line items" do
        line_item = forecast.forecast_line_items.first
        patch property_utility_provider_forecast_path(property, utility_provider, forecast), params: {
          forecast: {
            forecast_line_items_attributes: [
              {id: line_item.id, name: "Updated Forecast", amount: 200.00, due_date: line_item.due_date}
            ]
          }
        }
        line_item.reload
        expect(line_item.name).to eq("Updated Forecast")
        expect(line_item.amount).to eq(200.00)
      end

      it "adds new line items" do
        line_item = forecast.forecast_line_items.first
        patch property_utility_provider_forecast_path(property, utility_provider, forecast), params: {
          forecast: {
            forecast_line_items_attributes: [
              {id: line_item.id, name: line_item.name, amount: line_item.amount, due_date: line_item.due_date},
              {name: "New Item", amount: 50.00, due_date: Date.today + 90.days}
            ]
          }
        }
        forecast.reload
        expect(forecast.forecast_line_items.count).to eq(2)
      end

      it "removes line items when _destroy is set" do
        line_item = forecast.forecast_line_items.first
        patch property_utility_provider_forecast_path(property, utility_provider, forecast), params: {
          forecast: {
            forecast_line_items_attributes: [
              {id: line_item.id, _destroy: "1"}
            ]
          }
        }
        forecast.reload
        expect(forecast.forecast_line_items.count).to eq(0)
      end

      it "redirects to the forecast show page" do
        patch property_utility_provider_forecast_path(property, utility_provider, forecast), params: {
          forecast: {
            issued_date: Date.today
          }
        }
        expect(response).to redirect_to(property_utility_provider_forecast_path(property, utility_provider, forecast))
      end
    end

    context "with invalid parameters" do
      it "does not update with empty issued_date" do
        original_date = forecast.issued_date
        patch property_utility_provider_forecast_path(property, utility_provider, forecast), params: {
          forecast: {
            issued_date: ""
          }
        }
        forecast.reload
        expect(forecast.issued_date).to eq(original_date)
      end

      it "renders the edit template with errors" do
        patch property_utility_provider_forecast_path(property, utility_provider, forecast), params: {
          forecast: {
            issued_date: ""
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /properties/:property_id/utility_providers/:utility_provider_id/forecasts/:id" do
    let!(:forecast) do
      Forecast.create!(
        utility_provider: utility_provider,
        property: property,
        issued_date: Date.today
      )
    end

    it "destroys the forecast" do
      expect {
        delete property_utility_provider_forecast_path(property, utility_provider, forecast)
      }.to change(Forecast, :count).by(-1)
    end

    it "destroys associated line items" do
      ForecastLineItem.create!(forecast: forecast, name: "Test", amount: 100, due_date: Date.today)
      expect {
        delete property_utility_provider_forecast_path(property, utility_provider, forecast)
      }.to change(ForecastLineItem, :count).by(-1)
    end

    it "redirects to the property show page" do
      delete property_utility_provider_forecast_path(property, utility_provider, forecast)
      expect(response).to redirect_to(property_path(property))
    end
  end
end
