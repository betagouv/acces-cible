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

  describe "#applicable_total" do
    subject(:applicable_total) { check.applicable_total }

    context "when check is not completed" do
      before { allow(check).to receive(:completed?).and_return(false) }

      it "returns nil" do
        expect(applicable_total).to be_nil
      end
    end

    context "when check is completed" do
      before do
        allow(check).to receive(:completed?).and_return(true)
        check.passes = 10
        check.incomplete = 5
        check.violations = 3
      end

      it "returns sum of passes, incomplete, and violations" do
        expect(applicable_total).to eq(18)
      end
    end
  end

  describe "#checks_total" do
    subject(:checks_total) { check.checks_total }

    context "when check is not completed" do
      before { allow(check).to receive(:completed?).and_return(false) }

      it "returns nil" do
        expect(checks_total).to be_nil
      end
    end

    context "when check is completed" do
      before do
        allow(check).to receive_messages(completed?: true, applicable_total: 18)
        check.inapplicable = 2
      end

      it "returns sum of applicable_total and inapplicable" do
        expect(checks_total).to eq(20)
      end
    end
  end

  describe "#success_rate" do
    subject(:success_rate) { check.success_rate }

    context "when check is not completed" do
      before { allow(check).to receive(:completed?).and_return(false) }

      it "returns nil" do
        expect(success_rate).to be_nil
      end
    end

    context "when check is completed" do
      before do
        allow(check).to receive(:completed?).and_return(true)
        check.passes = 15
        check.incomplete = 3
        check.violations = 2
      end

      it "calculates success rate as percentage" do
        expect(success_rate).to eq(90.0)
      end
    end
  end

  describe "#custom_badge_status" do
    subject(:badge_status) { check.custom_badge_status }

    {
      100 => :success,
      90 => :new,
      75 => :new,
      50 => :new,
      25 => :warning,
      10 => :warning,
      1 => :warning,
      0 => :error,
      nil => :error
    }.each do |rate, expected_status|
      context "when success_rate is #{rate || 'nil'}" do
        before { allow(check).to receive(:success_rate).and_return(rate) }

        it "returns #{expected_status}" do
          expect(badge_status).to eq(expected_status)
        end
      end
    end
  end

  describe "#tooltip?" do
    subject(:tooltip) { check.tooltip? }

    context "when check is completed" do
      before { allow(check).to receive(:completed?).and_return(true) }

      it "returns false" do
        expect(tooltip).to be false
      end
    end

    context "when check is not completed" do
      before { allow(check).to receive(:completed?).and_return(false) }

      it "returns true" do
        expect(tooltip).to be true
      end
    end
  end
end
