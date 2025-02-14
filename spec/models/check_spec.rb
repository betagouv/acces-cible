require "rails_helper"

RSpec.describe Check do
  describe "associations" do
    it { is_expected.to belong_to(:audit) }
  end

  describe "enums" do
    it do
      should define_enum_for(:status)
        .validating
        .with_values(["pending", "running", "passed", "retryable", "failed"].index_by(&:itself))
        .backed_by_column_of_type(:string)
        .with_default(:pending)
    end
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:parsed_url).to(:audit) }
    it { is_expected.to delegate_method(:human_type).to(:class) }
  end

  describe "scopes" do
    let!(:pending_check) { create(:check, status: :pending, run_at: 1.hour.ago) }
    let!(:running_check) { create(:check, status: :running, run_at: 2.hours.ago) }
    let!(:passed_check) { create(:check, status: :passed, attempts: 0) }
    let!(:retried_passed_check) { create(:check, status: :passed, attempts: 2) }
    let!(:failed_check) { create(:check, status: :failed, attempts: Check::MAX_ATTEMPTS) }
    let!(:retryable_check) { create(:check, status: :retryable) }
    let!(:future_check) { create(:check, status: :pending, run_at: 1.hour.from_now) }

    describe ".due" do
      it "returns pending checks with run_at in the past" do
        expect(described_class.due).to contain_exactly(pending_check)
      end
    end

    describe ".past" do
      it "returns checks with passed or failed status" do
        expect(described_class.past).to contain_exactly(passed_check, retried_passed_check, failed_check)
      end
    end

    describe ".scheduled" do
      it "returns checks with future run_at" do
        expect(described_class.scheduled).to contain_exactly(future_check)
      end
    end

    describe ".to_run" do
      it "returns due and retryable checks" do
        expect(described_class.to_run).to contain_exactly(pending_check, retryable_check)
      end
    end

    describe ".clean" do
      it "returns passed checks with zero attempts" do
        expect(described_class.clean).to contain_exactly(passed_check)
      end
    end

    describe ".late" do
      it "returns pending checks more than an hour old" do
        expect(described_class.late).to contain_exactly(pending_check)
      end
    end

    describe ".retried" do
      it "returns passed checks with at least one attempt" do
        expect(described_class.retried).to contain_exactly(retried_passed_check)
      end
    end

    describe ".stalled" do
      it "returns running checks older than MAX_RUNTIME" do
        expect(described_class.stalled).to contain_exactly(running_check)
      end
    end

    describe ".crashed" do
      it "returns failed checks with maximum attempts" do
        expect(described_class.crashed).to contain_exactly(failed_check)
      end
    end
  end

  describe "instance methods" do
    describe "#human_status" do
      it "returns the humanized status" do
        check = build(:check, status: :pending)
        expect(Check).to receive(:human).with("status.pending")
        check.human_status
      end
    end

    describe "#human_checked_at" do
      it "formats the checked_at timestamp" do
        check = build(:check, checked_at: Time.zone.parse("2024-02-14 10:00:00"))
        expect(check.human_checked_at).to eq(I18n.l(check.checked_at, format: :long))
      end
    end

    describe "#to_partial_path" do
      it "returns the singular model name" do
        expect(subject.to_partial_path).to eq("check")
      end
    end

    describe "#due?" do
      it "returns true for pending checks with past run_at" do
        check = build(:check, status: :pending, run_at: 1.minute.ago)
        expect(check).to be_due
      end

      it "returns false for pending checks with future run_at" do
        check = build(:check, status: :pending, run_at: 1.minute.from_now)
        expect(check).not_to be_due
      end

      it "returns false for non-pending checks" do
        check = build(:check, status: :running, run_at: 1.minute.ago)
        expect(check).not_to be_due
      end
    end

    describe "#runnable?" do
      it "returns true for due checks" do
        check = build(:check, status: :pending, run_at: 1.minute.ago)
        expect(check).to be_runnable
      end

      it "returns true for retryable checks" do
        check = build(:check, status: :retryable)
        expect(check).to be_runnable
      end

      it "returns false for other checks" do
        check = build(:check, status: :running)
        expect(check).not_to be_runnable
      end
    end

    describe "#root_page" do
      it "creates a Page with the audit URL" do
        audit = build(:audit, url: "https://example.com/")
        check = build(:check, audit:)
        expect(Page).to receive(:new).with("https://example.com/")
        check.root_page
      end
    end
  end
end
