require "rails_helper"

RSpec.describe "UtilityProviders", type: :request do
  let(:property) { Property.create!(name: "Test Property") }
  let(:utility_type1) { UtilityType.create!(name: "Heating") }
  let(:utility_type2) { UtilityType.create!(name: "Water") }

  describe "GET /properties/:property_id/utility_providers/new" do
    it "renders the new template" do
      get new_property_utility_provider_path(property)
      expect(response).to have_http_status(:success)
    end

    it "displays available utility types" do
      utility_type1
      utility_type2
      get new_property_utility_provider_path(property)
      expect(response.body).to include("Heating")
      expect(response.body).to include("Water")
    end
  end

  describe "POST /properties/:property_id/utility_providers" do
    context "with valid parameters" do
      it "creates a new utility provider" do
        expect {
          post property_utility_providers_path(property), params: {
            utility_provider: {
              name: "Test Provider",
              forecast_behavior: "zero_after_expiry",
              utility_type_ids: [utility_type1.id, utility_type2.id]
            }
          }
        }.to change(UtilityProvider, :count).by(1)
      end

      it "assigns utility types to the provider" do
        post property_utility_providers_path(property), params: {
          utility_provider: {
            name: "Test Provider",
            forecast_behavior: "zero_after_expiry",
            utility_type_ids: [utility_type1.id, utility_type2.id]
          }
        }
        provider = UtilityProvider.last
        expect(provider.utility_types).to include(utility_type1, utility_type2)
      end

      it "redirects to the utility provider show page" do
        post property_utility_providers_path(property), params: {
          utility_provider: {
            name: "Test Provider",
            forecast_behavior: "zero_after_expiry"
          }
        }
        provider = UtilityProvider.last
        expect(response).to redirect_to(property_utility_provider_path(property, provider))
      end
    end

    context "with invalid parameters" do
      it "does not create a new utility provider without name" do
        expect {
          post property_utility_providers_path(property), params: {
            utility_provider: {
              name: "",
              forecast_behavior: "zero_after_expiry"
            }
          }
        }.not_to change(UtilityProvider, :count)
      end

      it "renders the new template with errors" do
        post property_utility_providers_path(property), params: {
          utility_provider: {
            name: "",
            forecast_behavior: "zero_after_expiry"
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create duplicate utility providers for the same property" do
        UtilityProvider.create!(name: "Test Provider", forecast_behavior: "zero_after_expiry", property: property)
        expect {
          post property_utility_providers_path(property), params: {
            utility_provider: {
              name: "Test Provider",
              forecast_behavior: "carry_forward"
            }
          }
        }.not_to change(UtilityProvider, :count)
      end
    end
  end

  describe "GET /properties/:property_id/utility_providers/:id" do
    let(:utility_provider) do
      UtilityProvider.create!(name: "Test Provider", forecast_behavior: "zero_after_expiry", property: property)
    end

    it "renders the show template" do
      get property_utility_provider_path(property, utility_provider)
      expect(response).to have_http_status(:success)
    end

    it "displays utility provider information" do
      utility_provider.utility_types << utility_type1
      get property_utility_provider_path(property, utility_provider)
      expect(response.body).to include("Test Provider")
      expect(response.body).to include("Heating")
    end
  end

  describe "GET /properties/:property_id/utility_providers/:id/edit" do
    let(:utility_provider) do
      UtilityProvider.create!(name: "Test Provider", forecast_behavior: "zero_after_expiry", property: property)
    end

    it "renders the edit template" do
      get edit_property_utility_provider_path(property, utility_provider)
      expect(response).to have_http_status(:success)
    end

    it "displays current utility type selections" do
      utility_provider.utility_types << utility_type1
      get edit_property_utility_provider_path(property, utility_provider)
      expect(response.body).to include("checked")
    end
  end

  describe "PATCH /properties/:property_id/utility_providers/:id" do
    let(:utility_provider) do
      UtilityProvider.create!(name: "Test Provider", forecast_behavior: "zero_after_expiry", property: property)
    end

    context "with valid parameters" do
      it "updates the utility provider" do
        patch property_utility_provider_path(property, utility_provider), params: {
          utility_provider: {
            name: "Updated Provider",
            forecast_behavior: "carry_forward"
          }
        }
        utility_provider.reload
        expect(utility_provider.name).to eq("Updated Provider")
        expect(utility_provider.carry_forward?).to be true
      end

      it "updates utility type associations" do
        utility_provider.utility_types << utility_type1
        patch property_utility_provider_path(property, utility_provider), params: {
          utility_provider: {
            name: "Test Provider",
            forecast_behavior: "zero_after_expiry",
            utility_type_ids: [utility_type2.id]
          }
        }
        utility_provider.reload
        expect(utility_provider.utility_types).not_to include(utility_type1)
        expect(utility_provider.utility_types).to include(utility_type2)
      end

      it "redirects to the utility provider show page" do
        patch property_utility_provider_path(property, utility_provider), params: {
          utility_provider: {
            name: "Updated Provider",
            forecast_behavior: "carry_forward"
          }
        }
        expect(response).to redirect_to(property_utility_provider_path(property, utility_provider))
      end
    end

    context "with invalid parameters" do
      it "does not update with empty name" do
        original_name = utility_provider.name
        patch property_utility_provider_path(property, utility_provider), params: {
          utility_provider: {
            name: "",
            forecast_behavior: "zero_after_expiry"
          }
        }
        utility_provider.reload
        expect(utility_provider.name).to eq(original_name)
      end

      it "renders the edit template with errors" do
        patch property_utility_provider_path(property, utility_provider), params: {
          utility_provider: {
            name: "",
            forecast_behavior: "zero_after_expiry"
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /properties/:property_id/utility_providers/:id" do
    let!(:utility_provider) do
      UtilityProvider.create!(name: "Test Provider", forecast_behavior: "zero_after_expiry", property: property)
    end

    it "destroys the utility provider" do
      expect {
        delete property_utility_provider_path(property, utility_provider)
      }.to change(UtilityProvider, :count).by(-1)
    end

    it "redirects to the property show page" do
      delete property_utility_provider_path(property, utility_provider)
      expect(response).to redirect_to(property_path(property))
    end
  end
end
