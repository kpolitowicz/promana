require "rails_helper"

RSpec.describe PayslipLineItem, type: :model do
  fixtures :properties, :tenants, :property_tenants

  let(:property) { properties(:property_one) }
  let(:tenant) { tenants(:tenant_one) }
  let(:property_tenant) { property_tenants(:property_tenant_one) }
  let(:payslip) { Payslip.create!(property: property, property_tenant: property_tenant, month: Date.today, due_date: Date.today) }

  describe "associations" do
    it "belongs to payslip" do
      association = PayslipLineItem.reflect_on_association(:payslip)
      expect(association).not_to be_nil
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "is valid with name and amount" do
      line_item = PayslipLineItem.new(payslip: payslip, name: Payslip.rent_label, amount: 1000.00)
      expect(line_item).to be_valid
    end

    it "requires name" do
      line_item = PayslipLineItem.new(payslip: payslip, amount: 1000.00)
      expect(line_item).not_to be_valid
      expect(line_item.errors[:name]).to include("can't be blank")
    end

    it "requires amount" do
      line_item = PayslipLineItem.new(payslip: payslip, name: Payslip.rent_label)
      expect(line_item).not_to be_valid
      expect(line_item.errors[:amount]).to include("can't be blank")
    end

    it "validates amount is numeric" do
      line_item = PayslipLineItem.new(payslip: payslip, name: Payslip.rent_label, amount: "not a number")
      expect(line_item).not_to be_valid
      expect(line_item.errors[:amount]).to include("is not a number")
    end

    it "allows negative amounts" do
      line_item = PayslipLineItem.new(payslip: payslip, name: "Adjustment", amount: -50.00)
      expect(line_item).to be_valid
    end
  end
end
