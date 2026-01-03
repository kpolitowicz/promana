require "rails_helper"

RSpec.describe "PropertySettings", type: :request do
  describe "GET /settings/properties" do
    it "returns a successful response" do
      get property_settings_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /settings/properties/new" do
    it "returns a successful response" do
      get new_property_setting_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /settings/properties" do
    context "with valid parameters" do
      it "creates a new property" do
        expect {
          post property_settings_path, params: {property: {name: "Test Property", address: "123 Test St"}}
        }.to change(Property, :count).by(1)
      end

      it "redirects to the created property setting" do
        post property_settings_path, params: {property: {name: "Test Property", address: "123 Test St"}}
        expect(response).to redirect_to(property_setting_path(Property.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new property" do
        expect {
          post property_settings_path, params: {property: {name: ""}}
        }.not_to change(Property, :count)
      end

      it "renders the new template" do
        post property_settings_path, params: {property: {name: ""}}
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /settings/properties/:id" do
    let(:property) { Property.create!(name: "Test Property", address: "123 Test St") }

    it "returns a successful response" do
      get property_setting_path(property)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /settings/properties/:id/edit" do
    let(:property) { Property.create!(name: "Test Property", address: "123 Test St") }

    it "returns a successful response" do
      get edit_property_setting_path(property)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /settings/properties/:id" do
    let(:property) { Property.create!(name: "Test Property", address: "123 Test St") }

    context "with valid parameters" do
      it "updates the property" do
        patch property_setting_path(property), params: {property: {name: "Updated Property"}}
        property.reload
        expect(property.name).to eq("Updated Property")
      end

      it "redirects to the property setting" do
        patch property_setting_path(property), params: {property: {name: "Updated Property"}}
        expect(response).to redirect_to(property_setting_path(property))
      end
    end

    context "with invalid parameters" do
      it "does not update the property" do
        patch property_setting_path(property), params: {property: {name: ""}}
        property.reload
        expect(property.name).to eq("Test Property")
      end

      it "renders the edit template" do
        patch property_setting_path(property), params: {property: {name: ""}}
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /settings/properties/:id" do
    let!(:property) { Property.create!(name: "Test Property", address: "123 Test St") }

    it "destroys the property" do
      expect {
        delete property_setting_path(property)
      }.to change(Property, :count).by(-1)
    end

    it "redirects to the property settings list" do
      delete property_setting_path(property)
      expect(response).to redirect_to(property_settings_path)
    end
  end
end
