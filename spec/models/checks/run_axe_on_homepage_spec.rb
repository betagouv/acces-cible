require "rails_helper"

RSpec.describe Checks::RunAxeOnHomepage do
  let(:check) { described_class.new }

  describe "#violation_data" do
    subject(:violation_data) { check.violation_data }

    context "when data is nil" do
      before { check.data = nil }

      it "returns empty array" do
        expect(violation_data).to eq([])
      end
    end

    context "when stored violation_data is empty" do
      before do
        check.data = { "violation_data" => [] }
      end

      it "returns empty array" do
        expect(violation_data).to eq([])
      end
    end

    context "when stored violation_data has violations" do
      let(:violation_hash) do
        {
          "id" => "color-contrast",
          "impact" => "serious",
          "description" => "Color contrast issue",
          "help" => "Fix color contrast",
          "help_url" => "https://example.com/help",
          "nodes" => [
            {
              "html" => "<div>Test</div>",
              "impact" => "serious",
              "target" => ["div"],
              "failure_summary" => "Contrast ratio is too low"
            }
          ]
        }
      end

      before do
        check.data = { "violation_data" => [violation_hash] }
        allow(AxeViolation).to receive(:new).and_return(instance_double(AxeViolation))
      end

      it "maps violation data to AxeViolation objects" do
        expect(AxeViolation).to receive(:new).with(violation_hash)
        violation_data
      end
    end
  end
end
