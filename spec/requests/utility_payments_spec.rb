require "rails_helper"

RSpec.describe "UtilityPayments", type: :request do
  let(:property) { Property.create!(name: "Test Property") }
  let(:utility_provider) { UtilityProvider.create!(property: property, name: "Test Provider", forecast_behavior: "zero_after_expiry") }

  describe "GET /properties/:property_id/utility_providers/:utility_provider_id/utility_payments" do
    it "returns http success" do
      get property_utility_provider_utility_payments_path(property, utility_provider)
      expect(response).to have_http_status(:success)
    end

    it "displays all utility payments" do
      UtilityPayment.create!(utility_provider: utility_provider, property: property, amount: 1000.00, paid_date: Date.today)
      UtilityPayment.create!(utility_provider: utility_provider, property: property, amount: 1200.00, paid_date: Date.today - 10.days)

      get property_utility_provider_utility_payments_path(property, utility_provider)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("1000.00")
      expect(response.body).to include("1200.00")
    end
  end

  describe "GET /properties/:property_id/utility_providers/:utility_provider_id/utility_payments/new" do
    it "returns http success" do
      get new_property_utility_provider_utility_payment_path(property, utility_provider)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /properties/:property_id/utility_providers/:utility_provider_id/utility_payments" do
    let(:paid_date) { Date.today }
    let(:amount) { 1000.00 }

    it "creates a new utility payment" do
      expect {
        post property_utility_provider_utility_payments_path(property, utility_provider), params: {
          utility_payment: {
            amount: amount,
            paid_date: paid_date
          }
        }
      }.to change(UtilityPayment, :count).by(1)
    end

    it "redirects to the payment show page" do
      post property_utility_provider_utility_payments_path(property, utility_provider), params: {
        utility_payment: {
          amount: amount,
          paid_date: paid_date
        }
      }
      payment = UtilityPayment.last
      expect(response).to redirect_to(property_utility_provider_utility_payment_path(property, utility_provider, payment))
    end

    it "sets the property and utility_provider associations" do
      post property_utility_provider_utility_payments_path(property, utility_provider), params: {
        utility_payment: {
          amount: amount,
          paid_date: paid_date
        }
      }
      payment = UtilityPayment.last
      expect(payment.property).to eq(property)
      expect(payment.utility_provider).to eq(utility_provider)
    end

    context "with invalid parameters" do
      it "does not create with empty amount" do
        expect {
          post property_utility_provider_utility_payments_path(property, utility_provider), params: {
            utility_payment: {
              amount: "",
              paid_date: paid_date
            }
          }
        }.not_to change(UtilityPayment, :count)
      end

      it "renders the new template with errors" do
        post property_utility_provider_utility_payments_path(property, utility_provider), params: {
          utility_payment: {
            amount: "",
            paid_date: paid_date
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /properties/:property_id/utility_providers/:utility_provider_id/utility_payments/:id" do
    let(:payment) do
      UtilityPayment.create!(
        utility_provider: utility_provider,
        property: property,
        amount: 1000.00,
        paid_date: Date.today
      )
    end

    it "returns http success" do
      get property_utility_provider_utility_payment_path(property, utility_provider, payment)
      expect(response).to have_http_status(:success)
    end

    it "displays the payment details" do
      get property_utility_provider_utility_payment_path(property, utility_provider, payment)
      expect(response.body).to include("1000.00")
      expect(response.body).to include(payment.paid_date.strftime("%B %d, %Y"))
    end
  end

  describe "GET /properties/:property_id/utility_providers/:utility_provider_id/utility_payments/:id/edit" do
    let(:payment) do
      UtilityPayment.create!(
        utility_provider: utility_provider,
        property: property,
        amount: 1000.00,
        paid_date: Date.today
      )
    end

    it "returns http success" do
      get edit_property_utility_provider_utility_payment_path(property, utility_provider, payment)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /properties/:property_id/utility_providers/:utility_provider_id/utility_payments/:id" do
    let(:payment) do
      UtilityPayment.create!(
        utility_provider: utility_provider,
        property: property,
        amount: 1000.00,
        paid_date: Date.today
      )
    end

    it "updates the payment" do
      patch property_utility_provider_utility_payment_path(property, utility_provider, payment), params: {
        utility_payment: {
          amount: 1200.00
        }
      }
      payment.reload
      expect(payment.amount).to eq(1200.00)
    end

    it "redirects to the payment show page" do
      patch property_utility_provider_utility_payment_path(property, utility_provider, payment), params: {
        utility_payment: {
          amount: 1200.00
        }
      }
      expect(response).to redirect_to(property_utility_provider_utility_payment_path(property, utility_provider, payment))
    end

    context "with invalid parameters" do
      it "does not update with empty amount" do
        original_amount = payment.amount
        patch property_utility_provider_utility_payment_path(property, utility_provider, payment), params: {
          utility_payment: {
            amount: ""
          }
        }
        payment.reload
        expect(payment.amount).to eq(original_amount)
      end

      it "renders the edit template with errors" do
        patch property_utility_provider_utility_payment_path(property, utility_provider, payment), params: {
          utility_payment: {
            amount: ""
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /properties/:property_id/utility_providers/:utility_provider_id/utility_payments/:id" do
    let!(:payment) do
      UtilityPayment.create!(
        utility_provider: utility_provider,
        property: property,
        amount: 1000.00,
        paid_date: Date.today
      )
    end

    it "destroys the payment" do
      expect {
        delete property_utility_provider_utility_payment_path(property, utility_provider, payment)
      }.to change(UtilityPayment, :count).by(-1)
    end

    it "redirects to the payments index" do
      delete property_utility_provider_utility_payment_path(property, utility_provider, payment)
      expect(response).to redirect_to(property_utility_provider_utility_payments_path(property, utility_provider))
    end
  end
end
