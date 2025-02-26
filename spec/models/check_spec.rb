require "rails_helper"

RSpec.describe Check do
  describe "associations" do
    it { is_expected.to belong_to(:audit) }
  end

  describe "enums" do
    it do
      should define_enum_for(:status)
        .validating
        .with_values(["pending", "passed", "failed"].index_by(&:itself))
        .backed_by_column_of_type(:string)
        .with_default(:pending)
    end
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:parsed_url).to(:audit) }
    it { is_expected.to delegate_method(:human_type).to(:class) }
  end

  describe "scopes" do
    let!(:pending_check) { create(:check, status: :pending, run_at: 1.hour.ago, scheduled: false) }
    let!(:scheduled_check) { create(:check, status: :pending, run_at: 1.hour.ago, scheduled: true) }
    let!(:future_check) { create(:check, status: :pending, run_at: 1.hour.from_now, scheduled: false) }
    let!(:passed_check) { create(:check, status: :passed) }

    describe ".due" do
      it "returns pending checks with run_at in the past" do
        expect(described_class.due).to include(pending_check, scheduled_check)
        expect(described_class.due).not_to include(future_check, passed_check)
      end
    end

    describe ".scheduled" do
      it "returns checks marked as scheduled" do
        expect(described_class.scheduled).to include(scheduled_check)
        expect(described_class.scheduled).not_to include(pending_check)
      end
    end

    describe ".unscheduled" do
      it "returns checks not marked as scheduled" do
        expect(described_class.unscheduled).to include(pending_check, future_check, passed_check)
        expect(described_class.unscheduled).not_to include(scheduled_check)
      end
    end

    describe ".to_schedule" do
      it "returns due and unscheduled checks" do
        expect(described_class.to_schedule).to include(pending_check)
        expect(described_class.to_schedule).not_to include(scheduled_check)
      end
    end

    describe ".to_run" do
      it "returns due and scheduled checks" do
        expect(described_class.to_run).to include(scheduled_check)
        expect(described_class.to_run).not_to include(pending_check, future_check, passed_check)
      end
    end
  end

  describe "class methods" do
    describe ".types" do
      it "returns a hash of check type symbols mapped to their classes" do
        expect(described_class.types).to be_a(Hash)
        expect(described_class.types.keys).to all(be_a(Symbol))
        expect(described_class.types.values).to all(be_a(Class))
      end
    end

    describe ".names" do
      it "returns an array of check type symbols" do
        expect(described_class.names).to match_array(Check::TYPES)
      end
    end

    describe ".classes" do
      it "returns an array of check classes" do
        expect(described_class.classes).to all(be_a(Class))
      end
    end
  end

  describe "#run_at" do
    context "when run_at is set" do
      it "returns the set time" do
        time = 1.hour.ago
        check = build(:check, run_at: time)
        expect(check.run_at).to be_within(1.second).of(time)
      end
    end

    context "when run_at is nil" do
      it "returns current time" do
        check = build(:check, run_at: nil, audit: nil)
        expect(check.run_at).to be_within(1.second).of(Time.current)
      end
    end
  end

  describe "#human_status" do
    it "returns the humanized status" do
      check = build(:check, status: :pending)
      expect(described_class).to receive(:human).with("status.pending")
      check.human_status
    end
  end

  describe "#human_checked_at" do
    context "when checked_at is present" do
      it "formats the checked_at timestamp" do
        time = Time.zone.parse("2024-02-14 10:00:00")
        check = build(:check, checked_at: time)
        expect(check.human_checked_at).to eq(I18n.l(time, format: :long))
      end
    end

    context "when checked_at is nil" do
      it "returns nil" do
        check = build(:check, checked_at: nil)
        expect(check.human_checked_at).to be_nil
      end
    end
  end

  describe "#due?" do
    it "returns true for persisted pending checks with past run_at" do
      check = create(:check, status: :pending, run_at: 1.minute.ago)
      expect(check).to be_due
    end

    it "returns false for new records" do
      check = build(:check, status: :pending, run_at: 1.minute.ago)
      expect(check).not_to be_due
    end

    it "returns false for pending checks with future run_at" do
      check = create(:check, status: :pending, run_at: 1.minute.from_now)
      expect(check).not_to be_due
    end

    it "returns false for non-pending checks" do
      check = create(:check, status: :passed, run_at: 1.minute.ago)
      expect(check).not_to be_due
    end
  end

  describe "#root_page" do
    it "returns a Page with the audit URL" do
      audit = build(:audit, url: "https://example.com/")
      check = build(:check, audit:)
      expect(Page).to receive(:new).with("https://example.com/")
      check.root_page
    end
  end

  describe "#to_badge" do
    subject(:to_badge) { check.to_badge }

    context "when check is passed" do
      let(:check) { build(:check, status: :passed) }

      it "returns success level and custom text if available" do
        allow(check).to receive_messages(respond_to?: true, custom_badge_status: :success, custom_badge_text: "Custom text")
        expect(to_badge).to eq([:success, "Custom text"])
      end

      it "returns success level and human status if no custom text" do
        allow(check).to receive(:respond_to?).and_return(false)
        expect(to_badge).to eq([:success, check.human_status])
      end
    end

    context "when check is pending" do
      let(:check) { build(:check, status: :pending) }

      it { is_expected.to eq([:info, check.human_status]) }
    end

    context "when check is failed" do
      let(:check) { build(:check, status: :failed) }

      it { is_expected.to eq([:error, check.human_status]) }
    end
  end

  describe "#run" do
    let(:check) { create(:check) }

    context "when analysis succeeds" do
      before do
        allow(check).to receive(:analyze!).and_return({ result: "success" })
      end

      it "marks the check as passed", :aggregate_failures do
        check.run
        check.reload
        expect(check).to be_passed
        expect(check.data).to eq({ "result" => "success" })
        expect(check.checked_at).to be_within(1.second).of(Time.current)
      end
    end

    context "when analysis fails" do
      let(:error) { StandardError.new("Test error") }

      before do
        allow(check).to receive(:analyze!).and_raise(error)
      end

      it "marks the check as failed", :aggregate_failures do
        check.run
        check.reload
        expect(check).to be_failed
        expect(check.data).to eq({
          "error" => "Test error",
          "error_type" => "StandardError"
        })
        expect(check.checked_at).to be_within(1.second).of(Time.current)
      end
    end
  end
end
