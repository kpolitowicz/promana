require "rails_helper"

RSpec.describe Payslip, type: :model do
  fixtures :properties, :tenants, :property_tenants

  let(:property) { properties(:property_one) }
  let(:tenant) { tenants(:tenant_one) }
  let(:property_tenant) { property_tenants(:property_tenant_one) }

  describe "associations" do
    it "belongs to property" do
      association = Payslip.reflect_on_association(:property)
      expect(association).not_to be_nil
      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to property_tenant" do
      association = Payslip.reflect_on_association(:property_tenant)
      expect(association).not_to be_nil
      expect(association.macro).to eq(:belongs_to)
    end

    it "has many payslip_line_items" do
      association = Payslip.reflect_on_association(:payslip_line_items)
      expect(association).not_to be_nil
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe "validations" do
    it "is valid with month and due_date" do
      payslip = Payslip.new(property: property, property_tenant: property_tenant, month: Date.today, due_date: Date.today + 10.days)
      expect(payslip).to be_valid
    end

    it "requires month" do
      payslip = Payslip.new(property: property, property_tenant: property_tenant, due_date: Date.today)
      expect(payslip).not_to be_valid
      expect(payslip.errors[:month]).to include("can't be blank")
    end

    it "requires due_date" do
      payslip = Payslip.new(property: property, property_tenant: property_tenant, month: Date.today)
      expect(payslip).not_to be_valid
      expect(payslip.errors[:due_date]).to include("can't be blank")
    end

    it "requires unique property_tenant and month combination" do
      Payslip.create!(property: property, property_tenant: property_tenant, month: Date.today.beginning_of_month, due_date: Date.today)
      duplicate = Payslip.new(property: property, property_tenant: property_tenant, month: Date.today.beginning_of_month, due_date: Date.today)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:property_id]).to include("has already been taken")
    end
  end

  describe "#total_amount" do
    it "sums all line item amounts" do
      payslip = Payslip.create!(property: property, property_tenant: property_tenant, month: Date.today, due_date: Date.today)
      payslip.payslip_line_items.create!(name: Payslip.rent_label, amount: 1000.00)
      payslip.payslip_line_items.create!(name: "Utilities", amount: 250.50)
      expect(payslip.total_amount).to eq(1250.50)
    end

    it "returns 0 when there are no line items" do
      payslip = Payslip.create!(property: property, property_tenant: property_tenant, month: Date.today, due_date: Date.today)
      expect(payslip.total_amount).to eq(0)
    end
  end

  describe "#tenant" do
    it "returns the tenant through property_tenant" do
      payslip = Payslip.create!(property: property, property_tenant: property_tenant, month: Date.today, due_date: Date.today)
      expect(payslip.tenant).to eq(tenant)
    end
  end

  describe ".name_header" do
    it "returns the name header label" do
      expect(Payslip.name_header).to eq("Pozycja")
    end
  end

  describe ".amount_header" do
    it "returns the amount header label" do
      expect(Payslip.amount_header).to eq("Kwota")
    end
  end

  describe ".total_header" do
    it "returns the total header label" do
      expect(Payslip.total_header).to eq("Razem")
    end
  end

  describe ".underpayment_label" do
    it "returns the underpayment label" do
      expect(Payslip.underpayment_label).to eq("Zaległe")
    end
  end

  describe ".overpayment_label" do
    it "returns the overpayment label" do
      expect(Payslip.overpayment_label).to eq("Nadpłata")
    end
  end

  describe ".rent_label" do
    it "returns the rent label" do
      expect(Payslip.rent_label).to eq("Czynsz")
    end
  end
end
