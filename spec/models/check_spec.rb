require "rails_helper"

RSpec.describe Check do
  subject(:check) { build(:check) }

  let(:retryable_error) { Check::RETRYABLE_ERRORS.first }

  it { should be_valid }

  describe "associations" do
    it { should belong_to(:audit) }
  end

  describe "enums" do
    it do
      should define_enum_for(:status)
        .validating
        .with_values(["pending", "passed", "failed", "blocked"].index_by(&:itself))
        .backed_by_column_of_type(:string)
        .with_default(:pending)
    end
  end

  describe "delegations" do
    it { should delegate_method(:parsed_url).to(:audit) }
    it { should delegate_method(:human_type).to(:class) }
  end

  describe "scopes" do
    let!(:pending_check) { create(:check, status: :pending, run_at: 1.hour.ago) }
    let!(:future_check) { create(:check, status: :pending, run_at: 1.hour.from_now) }
    let!(:passed_check) { create(:check, status: :passed) }
    let!(:failed_check_retryable) { create(:check, status: :failed, retry_count: 1, retry_at: 1.hour.ago, error_type: retryable_error) }
    let!(:failed_check_max_retries) { create(:check, status: :failed, retry_count: 3, retry_at: 1.hour.ago, error_type: retryable_error) }
    let!(:blocked_check_retryable) { create(:check, status: :blocked, retry_count: 0, retry_at: 1.hour.ago, error_type: retryable_error) }
    let!(:future_retry_check) { create(:check, status: :failed, retry_count: 1, retry_at: 1.hour.from_now) }

    describe ".to_run" do
      it "returns due and retryable checks" do
        expect(described_class.to_run).to include(pending_check)
        expect(described_class.to_run).not_to include(future_check, passed_check)
      end
    end

    describe ".to_retry" do
      it "returns failed or blocked checks that can be retried and are due" do
        expect(described_class.to_retry).to include(failed_check_retryable, blocked_check_retryable)
        expect(described_class.to_retry).not_to include(future_retry_check, failed_check_max_retries, pending_check)
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
      expect(Page).to receive(:new).with(url: "https://example.com/")
      check.root_page
    end
  end

  describe "#run" do
    let(:check) { build(:check) }

    context "when check is waiting on requirements" do
      before do
        allow(check).to receive(:waiting?).and_return(true)
      end

      it "returns false without running" do
        expect(check.run).to be false
      end

      it "does not call analyze!" do
        expect(check).not_to receive(:analyze!)
        check.run
      end
    end

    context "when check is blocked by failed requirements" do
      before do
        allow(check).to receive_messages(waiting?: false, blocked?: true)
      end

      it "sets status to blocked" do
        check.run
        expect(check.status).to eq("blocked")
      end

      it "sets checked_at timestamp" do
        freeze_time do
          check.run
          expect(check.checked_at).to eq(Time.zone.now)
        end
      end

      it "sets retry_at for future retry" do
        # Mock the retryable? method to return true since blocked checks should be retryable
        allow(check).to receive(:retryable?).and_return(true)
        check.run
        expect(check.retry_at).to be > Time.current
      end

      it "returns false" do
        expect(check.run).to be false
      end

      it "does not call analyze!" do
        expect(check).not_to receive(:analyze!)
        check.run
      end
    end

    context "when check is not ready to retry yet" do
      before do
        allow(check).to receive_messages(waiting?: false, blocked?: false)
        check.retry_at = 1.hour.from_now
      end

      it "returns false without running" do
        expect(check.run).to be false
      end

      it "does not call analyze!" do
        expect(check).not_to receive(:analyze!)
        check.run
      end
    end

    context "when check requirements are met" do
      before do
        allow(check).to receive_messages(waiting?: false, analyze!: { result: "success" })
      end

      it "calls analyze!" do
        allow(check).to receive(:analyze!).and_return({ result: "success" })
        check.run
        expect(check).to have_received(:analyze!)
      end

      it "updates the check status to passed" do
        check.run
        expect(check.status).to eq("passed")
      end

      it "sets the data with analyze! results" do
        check.run
        expect(check.data).to eq({ "result" => "success" })
      end

      it "updates checked_at timestamp" do
        freeze_time do
          check.run
          expect(check.checked_at).to eq(Time.zone.now)
        end
      end

      it "resets retry_at to nil" do
        check.retry_at = 1.hour.ago
        check.run
        expect(check.retry_at).to be_nil
      end

      it "clears error details on pass" do
        check.error_type = "SomeError"
        check.error_message = "Some message"
        check.error_backtrace = ["line 1"]
        check.run
        expect(check.error_type).to be_nil
        expect(check.error_message).to be_nil
        expect(check.error_backtrace).to be_nil
      end

      it "returns true when passed" do
        expect(check.run).to be true
      end
    end

    context "when analyze! raises an error" do
      let(:error) { Ferrum::TimeoutError.new("Test error") }

      before do
        allow(check).to receive(:waiting?).and_return(false)
        allow(check).to receive(:analyze!).and_raise(error)
        allow(Rails.backtrace_cleaner).to receive(:clean).and_return(["backtrace line"])
      end

      it "catches the error and sets status to failed" do
        check.run
        expect(check.status).to eq("failed")
      end

      it "stores error details in dedicated columns" do
        check.run
        expect(check.error_type).to eq("Ferrum::TimeoutError")
        expect(check.error_message).to be_present
        expect(check.error_backtrace).to include("backtrace line")
      end

      it "updates checked_at timestamp" do
        freeze_time do
          check.run
          expect(check.checked_at).to eq(Time.zone.now)
        end
      end

      it "increments retry_count" do
        check.retry_count = 1
        check.run
        expect(check.retry_count).to eq(2)
      end

      it "sets retry_at" do
        check.retry_count = 1
        check.run
        expect(check.retry_at).to be > Time.current
      end

      it "returns false" do
        expect(check.run).to be false
      end
    end
  end

  describe "#retryable?" do
    it "returns true when check is failed, retry_count is less than max_retries, and error_type is retryable" do
      check = build(:check, status: :failed, retry_count: 2, error_type: retryable_error)
      expect(check).to be_retryable
    end

    it "returns false when retry_count is equal to max_retries" do
      check = build(:check, status: :failed, retry_count: 3, error_type: retryable_error)
      expect(check).not_to be_retryable
    end

    it "returns false when retry_count is greater than max_retries" do
      check = build(:check, status: :failed, retry_count: 4, error_type: retryable_error)
      expect(check).not_to be_retryable
    end

    it "returns false when check is not failed" do
      check = build(:check, status: :blocked, retry_count: 1, error_type: retryable_error)
      expect(check).not_to be_retryable
    end

    it "returns false when error_type is not retryable" do
      check = build(:check, status: :failed, retry_count: 1, error_type: "SomeOtherError")
      expect(check).not_to be_retryable
    end

    it "returns false when error_type is nil" do
      check = build(:check, status: :failed, retry_count: 1, error_type: nil)
      expect(check).not_to be_retryable
    end
  end

  describe "#calculate_retry_at" do
    let(:check) { build(:check, status: :failed, retry_count:, error_type: retryable_error) }
    let(:retry_count) { 1 }

    it "calculates exponential backoff based on retry_count" do
      freeze_time do
        # For retry_count = 1: 5 * (5^1) = 25 minutes
        expected_time = Time.current + 25.minutes
        expect(check.calculate_retry_at).to be_within(1.second).of(expected_time)
      end
    end

    context "with different retry counts" do
      let(:retry_count) { 2 }

      it "applies exponential backoff correctly" do
        freeze_time do
          # For retry_count = 2: 5 * (5^2) = 5 * 25 = 125 minutes
          expected_time = Time.current + 125.minutes
          expect(check.calculate_retry_at).to be_within(1.second).of(expected_time)
        end
      end
    end
  end

  describe "#priority" do
    context "when subclass defines PRIORITY" do
      let(:custom_check_class) do
        Class.new(described_class) do
          # Define the constant on our anonymous class
          const_set(:PRIORITY, 5)
        end
      end

      it "uses the subclass priority" do
        check = custom_check_class.new
        expect(check.priority).to eq(5)
      end
    end

    context "when subclass doesn't define PRIORITY" do
      let(:default_check_class) do
        Class.new(described_class)
        # No PRIORITY constant defined
      end

      it "defaults to Check::PRIORITY" do
        check = default_check_class.new
        expect(check.priority).to eq(described_class::PRIORITY)
      end
    end
  end

  describe "#requirements" do
    context "when subclass defines REQUIREMENTS" do
      let(:custom_check_class) do
        Class.new(described_class) do
          const_set(:REQUIREMENTS, [:reachable]) # Override REQUIREMENTS in custom subclass
        end
      end

      it "uses the subclass requirements" do
        check = custom_check_class.new
        expect(check.requirements).to eq [:reachable]
      end
    end

    context "when subclass doesn't define REQUIREMENTS" do
      let(:default_check_class) do
        Class.new(described_class) # No REQUIREMENTS override
      end

      it "defaults to Check::REQUIREMENTS" do
        check = default_check_class.new
        expect(check.requirements).to eq(described_class::REQUIREMENTS)
      end
    end
  end

  describe "#waiting?" do
    let(:audit) { instance_double(Audit) }
    let(:check) { build(:check, audit: nil) }
    let(:check_status) { :passed }
    let(:inquiry) { check_status.to_s.inquiry }

    before do
      allow(check).to receive_messages(audit:, requirements:)
      allow(audit).to receive(:check_status).with(anything).and_return(inquiry)
    end

    context "when requirements are nil" do
      let(:requirements) { nil }

      it "returns false" do
        expect(check.waiting?).to be false
      end
    end

    context "when requirements are present" do
      let(:requirements) { [:reachable] }

      context "when any required check is pending" do
        let(:check_status) { :pending }

        it "returns true" do
          expect(check.waiting?).to be true
        end
      end

      context "when all required checks passed" do
        let(:check_status) { :passed }

        it "returns false" do
          expect(check.waiting?).to be false
        end
      end
    end
  end

  describe "#blocked?" do
    let(:audit) { instance_double(Audit) }
    let(:check) { build(:check, audit: nil) }
    let(:check_status) { :passed }
    let(:inquiry) { check_status.to_s.inquiry }

    before do
      allow(check).to receive_messages(audit:, requirements:)
      allow(audit).to receive(:check_status).with(anything).and_return(inquiry)
    end

    context "when requirements are nil" do
      let(:requirements) { nil }

      it "returns false" do
        expect(check.blocked?).to be false
      end
    end

    context "when requirements are present" do
      let(:requirements) { [:reachable] }

      context "when any required check is pending" do
        let(:check_status) { :failed }

        it "returns true" do
          expect(check.blocked?).to be true
        end
      end

      context "when all required checks passed" do
        let(:check_status) { :passed }

        it "returns false" do
          expect(check.blocked?).to be false
        end
      end
    end
  end
end
