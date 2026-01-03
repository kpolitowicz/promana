require "rails_helper"

RSpec.describe "Properties", type: :request do
  describe "GET /properties" do
    it "returns a successful response" do
      get properties_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /properties/:id" do
    let(:property) { Property.create!(name: "Test Property", address: "123 Test St") }

    it "returns a successful response" do
      get property_path(property)
      expect(response).to have_http_status(:success)
    end
  end
end
