require "rails_helper"

RSpec.describe "Properties", type: :request do
  describe "GET /properties" do
    it "returns a successful response" do
      get properties_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /properties/new" do
    it "returns a successful response" do
      get new_property_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /properties" do
    context "with valid parameters" do
      it "creates a new property" do
        expect {
          post properties_path, params: {property: {name: "Test Property", address: "123 Test St"}}
        }.to change(Property, :count).by(1)
      end

      it "redirects to the created property" do
        post properties_path, params: {property: {name: "Test Property", address: "123 Test St"}}
        expect(response).to redirect_to(property_path(Property.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new property" do
        expect {
          post properties_path, params: {property: {name: ""}}
        }.not_to change(Property, :count)
      end

      it "renders the new template" do
        post properties_path, params: {property: {name: ""}}
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /properties/:id" do
    let(:property) { Property.create!(name: "Test Property", address: "123 Test St") }

    it "returns a successful response" do
      get property_path(property)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /properties/:id/edit" do
    let(:property) { Property.create!(name: "Test Property", address: "123 Test St") }

    it "returns a successful response" do
      get edit_property_path(property)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /properties/:id" do
    let(:property) { Property.create!(name: "Test Property", address: "123 Test St") }

    context "with valid parameters" do
      it "updates the property" do
        patch property_path(property), params: {property: {name: "Updated Property"}}
        property.reload
        expect(property.name).to eq("Updated Property")
      end

      it "redirects to the property" do
        patch property_path(property), params: {property: {name: "Updated Property"}}
        expect(response).to redirect_to(property_path(property))
      end
    end

    context "with invalid parameters" do
      it "does not update the property" do
        patch property_path(property), params: {property: {name: ""}}
        property.reload
        expect(property.name).to eq("Test Property")
      end

      it "renders the edit template" do
        patch property_path(property), params: {property: {name: ""}}
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /properties/:id" do
    let!(:property) { Property.create!(name: "Test Property", address: "123 Test St") }

    it "destroys the property" do
      expect {
        delete property_path(property)
      }.to change(Property, :count).by(-1)
    end

    it "redirects to the properties list" do
      delete property_path(property)
      expect(response).to redirect_to(properties_path)
    end
  end
end
