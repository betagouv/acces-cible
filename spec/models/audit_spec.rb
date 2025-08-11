require "rails_helper"

RSpec.describe Audit do
  subject(:audit) { build(:audit) }

  let(:site) { audit.site }

  it { should be_valid }

  describe "associations" do
    it { should belong_to(:site).touch(true) }
    it { should have_many(:checks).dependent(:destroy) }
  end

  describe "validations" do
    it { should allow_value("https://example.com").for(:url) }
    it { should_not allow_value("not-a-url").for(:url) }
  end

  describe "normalization" do
    it "normalizes URLs" do
      audit.url = "HTTPS://EXAMPLE.COM/path/"
      expect(audit.url).to eq("https://example.com/path/")
    end
  end

  describe "enums" do
    it do
      should define_enum_for(:status)
        .validating
        .with_values(["pending", "passed", "mixed", "failed"].index_by(&:itself))
        .backed_by_column_of_type(:string)
        .with_default(:pending)
    end
  end

  describe "scopes" do
    before { site.audit.destroy }

    it ".sort_by_newest returns audits in descending order by checked_at date" do
      oldest = create(:audit, site:, checked_at: 3.days.ago)
      older = create(:audit, site:, checked_at: 2.days.ago)
      newer = create(:audit, site:, checked_at: 1.day.ago)

      expect(described_class.sort_by_newest).to eq([newer, older, oldest])
    end

    it ".sort_by_url orders by URL ignoring protocol and www" do
      gamma = create(:audit, site:, url: "https://www.gamma.com")
      alpha = create(:audit, site:, url: "https://alpha.com/path")
      beta = create(:audit, site:, url: "http://www.beta.com")

      expect(described_class.sort_by_url).to eq([alpha, beta, gamma])
    end
  end

  describe "#all_checks" do
    subject(:checks) { build(:audit).all_checks }

    it "returns all checks, building missing ones" do
      expect(checks.size).to eq(Check.types.size)
      expect(checks.all?(&:new_record?)).to be true
    end
  end

  describe "#schedule" do
    subject(:schedule) { audit.schedule }

    let(:audit) { create(:audit) }

    it "enqueues a ProcessAuditJob" do
      expect { schedule }.to have_enqueued_job(ProcessAuditJob).with(audit)
    end
  end

  describe "#status_from_checks" do
    context "with new checks" do
      let(:audit) { build(:audit) }

      it "returns pending when any check is new" do
        expect(audit.status_from_checks).to eq(:pending)
      end
    end

    context "with existing checks of different statuses" do
      let(:audit) { create(:audit) }

      before do
        audit.all_checks.each { |check| check.passed!; check.save }
        audit.checks.last.update!(status: :failed)
      end

      it "returns mixed when checks have different statuses" do
        expect(audit.status_from_checks).to eq(:mixed)
      end
    end

    context "with existing checks of same status" do
      let(:audit) { create(:audit) }

      before do
        audit.all_checks.each { |check| check.update(status: :passed) }
      end

      it "returns the unified status when all checks have same status" do
        expect(audit.status_from_checks).to eq(:passed)
      end
    end
  end

  describe "#next_check" do
    let(:audit) { create(:audit) }
    let(:retryable_error) { Check::RETRYABLE_ERRORS.first }

    it 'returns pending check first' do
      pending_check = audit.checks.first
      pending_check.update!(status: :pending)

      expect(audit.next_check).to eq(pending_check)
    end

    it 'returns retryable check if no pending' do
      audit.checks.update_all(status: :passed)
      retryable_check = audit.checks.first
      retryable_check.update!(status: :failed, retry_at: 1.minute.ago, error_type: retryable_error)

      expect(audit.next_check).to eq(retryable_check)
    end

    it 'returns unblocked check if no pending or retryable' do
      audit.checks.update_all(status: :blocked)
      blocked_check = audit.checks.first
      blocked_check.update!(status: :blocked)
      allow(blocked_check).to receive(:blocked?).and_return(false)

      expect(audit.next_check).to eq(blocked_check)
    end

    it 'returns nil when no checks are available' do
      audit.checks.update_all(status: :passed)

      expect(audit.next_check).to be_nil
    end
  end

  describe "#update_from_checks" do
    let(:audit) { create(:audit) }

    it "updates status using status_from_checks" do
      allow(audit).to receive_messages(status_from_checks: :mixed, latest_checked_at: 1.hour.ago)

      audit.update_from_checks
      expect(audit.status).to eq("mixed")
    end

    it "updates checked_at using latest_checked_at" do
      checked_at = 1.hour.ago
      allow(audit).to receive_messages(status_from_checks: :passed, latest_checked_at: checked_at)

      audit.update_from_checks
      expect(audit.checked_at).to be_within(1.second).of(checked_at)
    end

    it "calls set_current_audit! on site when not pending" do
      allow(audit).to receive_messages(status_from_checks: :passed, latest_checked_at: 1.hour.ago)

      expect(audit.site).to receive(:set_current_audit!)
      audit.update_from_checks
    end

    it "does not call set_current_audit! on site when pending" do
      allow(audit).to receive_messages(status_from_checks: :pending, latest_checked_at: nil)

      expect(audit.site).not_to receive(:set_current_audit!)
      audit.update_from_checks
    end

    it "runs in a transaction" do
      expect(audit).to receive(:transaction).and_yield
      audit.update_from_checks
    end
  end

  describe "#create_checks" do
    subject(:create_checks) { audit.create_checks }

    let(:audit) { build(:audit) }

    it "creates all check types" do
      expect { create_checks }.to change(Check, :count).by(Check.types.size)
    end

    it "does not create duplicate checks" do
      audit.create_checks
      expect { create_checks }.not_to change(Check, :count)
    end
  end

  describe "after_create callback" do
    let(:audit) { build(:audit) }

    it "calls create_checks when audit is created" do
      expect(audit).to receive(:create_checks).and_call_original
      expect { audit.save! }.to change(Check, :count).by(Check.types.size)
    end
  end

  describe "#check_status(name)" do
    subject(:check_status) { audit.check_status(name) }

    let(:audit) { build(:audit) }
    let(:name) { Check.names.first }

    context "when check has not run" do
      before do
        allow(audit).to receive(name).and_return(nil)
      end

      it "returns pending" do
        expect(check_status.pending?).to be true
      end
    end

    context "when check has failed" do
      before do
        check = instance_double(Check.types[name].name, status: :failed)
        allow(audit).to receive(name).and_return(check)
      end

      it "returns failed" do
        expect(check_status.failed?).to be true
      end
    end

    context "when check has passed" do
      before do
        check = instance_double(Check.types[name].name, status: :passed)
        allow(audit).to receive(name).and_return(check)
      end

      it "returns true" do
        expect(check_status.passed?).to be true
      end
    end
  end
end
