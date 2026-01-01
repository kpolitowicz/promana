require 'rails_helper'

RSpec.describe Property, type: :model do
  it "is valid with a name" do
    property = Property.new(name: "Test Property")
    expect(property).to be_valid
  end

  it "requires a name" do
    property = Property.new
    expect(property).not_to be_valid
    expect(property.errors[:name]).to include("can't be blank")
  end
end
