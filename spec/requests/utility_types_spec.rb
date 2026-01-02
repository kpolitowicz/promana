require "rails_helper"

RSpec.describe "UtilityTypes", type: :request do
  fixtures :utility_types
  describe "GET /utility_types" do
    it "renders the index template" do
      get utility_types_path
      expect(response).to have_http_status(:success)
    end

    it "displays all utility types" do
      # Fixtures already create utility types
      get utility_types_path
      expect(response.body).to include("Energy")
      expect(response.body).to include("Property Management")
    end
  end

  describe "GET /utility_types/new" do
    it "renders the new template" do
      get new_utility_type_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /utility_types" do
    context "with valid parameters" do
      it "creates a new utility type" do
        expect {
          post utility_types_path, params: {utility_type: {name: "Unique Utility Type"}}
        }.to change(UtilityType, :count).by(1)
      end

      it "redirects to the utility types index" do
        post utility_types_path, params: {utility_type: {name: "Another Unique Type"}}
        expect(response).to redirect_to(utility_types_path)
      end
    end

    context "with invalid parameters" do
      it "does not create a new utility type without name" do
        expect {
          post utility_types_path, params: {utility_type: {name: ""}}
        }.not_to change(UtilityType, :count)
      end

      it "renders the new template with errors" do
        post utility_types_path, params: {utility_type: {name: ""}}
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create duplicate utility types" do
        # Fixture already creates utility_type_energia with name "Energy"
        expect {
          post utility_types_path, params: {utility_type: {name: "Energy"}}
        }.not_to change(UtilityType, :count)
      end
    end
  end

  describe "DELETE /utility_types/:id" do
    let(:utility_type) { utility_types(:utility_type_energy) }

    it "destroys the utility type" do
      expect {
        delete utility_type_path(utility_type)
      }.to change(UtilityType, :count).by(-1)
    end

    it "redirects to the utility types index" do
      delete utility_type_path(utility_type)
      expect(response).to redirect_to(utility_types_path)
    end
  end
end
