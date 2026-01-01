require "rails_helper"

RSpec.describe Tenant, type: :model do
  it "is valid with a name" do
    tenant = Tenant.new(name: "Test Tenant")
    expect(tenant).to be_valid
  end

  it "requires a name" do
    tenant = Tenant.new
    expect(tenant).not_to be_valid
    expect(tenant.errors[:name]).to include("can't be blank")
  end

  it "is valid with name, email, and phone" do
    tenant = Tenant.new(name: "Test Tenant", email: "test@example.com", phone: "123-456-7890")
    expect(tenant).to be_valid
  end
end
