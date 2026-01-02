require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#format_currency" do
    before do
      Rails.application.config.currency_symbol = "$"
      Rails.application.config.currency_position = "before"
    end

    context "with default position (before)" do
      it "formats currency with symbol before amount" do
        expect(helper.format_currency(1234.56)).to eq("$1234.56")
      end

      it "formats currency with 2 decimal places by default" do
        expect(helper.format_currency(100)).to eq("$100.00")
      end

      it "formats negative amounts correctly" do
        expect(helper.format_currency(-50.25)).to eq("$-50.25")
      end

      it "allows custom precision" do
        expect(helper.format_currency(1234.567, precision: 3)).to eq("$1234.567")
      end
    end

    context "with position after" do
      before do
        Rails.application.config.currency_position = "after"
      end

      it "formats currency with symbol after amount" do
        expect(helper.format_currency(1234.56)).to eq("1234.56 $")
      end

      it "formats negative amounts correctly" do
        expect(helper.format_currency(-50.25)).to eq("-50.25 $")
      end
    end

    context "with different currency symbols" do
      before do
        Rails.application.config.currency_symbol = "€"
        Rails.application.config.currency_position = "after"
      end

      it "uses the configured currency symbol" do
        expect(helper.format_currency(100)).to eq("100.00 €")
      end
    end
  end
end
