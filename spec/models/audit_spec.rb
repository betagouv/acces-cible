require "rails_helper"

RSpec.describe Audit do
  let(:site) { create(:site) }
  subject(:audit) { build(:audit, site: nil) }

  it "has a valid factory" do
    audit = build(:audit)
    expect(audit).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:site).touch(true) }
  end

  describe "validations" do
    it { is_expected.to allow_value("https://example.com").for(:url) }
    it { is_expected.not_to allow_value("not-a-url").for(:url) }
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
        .with_values(["pending", "running", "passed", "retryable", "failed"].index_by(&:itself))
        .backed_by_column_of_type(:string)
        .with_default(:pending)
    end
  end

  describe "scopes" do
    before { site.audit.destroy }
    it ".sort_by_newest returns audits in descending order by creation date" do
      oldest = create(:audit, site:, created_at: 3.days.ago)
      older = create(:audit, site:, created_at: 2.days.ago)
      newer = create(:audit, site:, created_at: 1.day.ago)

      expect(described_class.sort_by_newest).to eq([newer, older, oldest])
    end

    it ".sort_by_url orders by URL ignoring protocol and www" do
      alpha = create(:audit, site:, url: "https://alpha.com/path")
      beta = create(:audit, site:, url: "http://www.beta.com")
      gamma = create(:audit, site:, url: "https://www.gamma.com")

      expect(described_class.sort_by_url).to eq([alpha, beta, gamma])
    end

    it ".due returns pending audits with run_at in the past" do
      past_pending = create(:audit, :pending, site:, run_at: 1.hour.ago)
      create(:audit, :pending, site:, run_at: 1.hour.from_now) # future
      create(:audit, :passed, site:, run_at: 2.hours.ago)      # not pending

      expect(described_class.due).to eq([past_pending])
    end

    it ".to_run returns due and retryable audits" do
      past_pending = create(:audit, :pending, site:, run_at: 1.hour.ago)
      retryable = create(:audit, :failed, site:, attempts: Audit::MAX_ATTEMPTS - 1)

      # Create records that shouldn't be included
      create(:audit, :pending, site:, run_at: 1.hour.from_now) # not due
      create(:audit, :failed, site:, attempts: Audit::MAX_ATTEMPTS) # not retryable
      create(:audit, :passed, site:) # wrong status

      expect(described_class.to_run).to match_array([past_pending, retryable])
    end

    context "with audits" do
      let!(:passed_audit) { create(:audit, :passed, site:, created_at: 7.days.ago, url: "https://beta.com") }
      let!(:failed_audit) { create(:audit, :failed, site:, created_at: 6.days.ago, url: "https://alpha.com") }
      let!(:pending_audit) { create(:audit, :pending, site:, run_at: 1.hour.ago, created_at: 5.days.ago) }
      let!(:future_audit) { create(:audit, :pending, site:, run_at: 1.hour.from_now, created_at: 4.days.ago) }
      let!(:retried_audit) { create(:audit, :passed, site:, attempts: 2, created_at: 3.days.ago) }
      let!(:running_audit) { create(:audit, :running, site:, run_at: 2.hours.ago, created_at: 2.days.ago) }
      let!(:crashed_audit) { create(:audit, :failed, site:, attempts: Audit::MAX_ATTEMPTS, created_at: 1.day.ago) }

      it ".past returns passed and failed audits" do
        expect(described_class.past).to contain_exactly(passed_audit, failed_audit, retried_audit, crashed_audit)
      end

      it ".scheduled returns audits with future run_at" do
        expect(described_class.scheduled).to eq([future_audit])
      end

      it ".retryable returns failed audits with attempts less than MAX_ATTEMPTS" do
        expect(described_class.retryable).to eq([failed_audit])
      end

      it ".clean returns passed audits with no attempts" do
        expect(described_class.clean).to eq([passed_audit])
      end

      it ".late returns pending audits overdue by an hour" do
        expect(described_class.late).to eq([pending_audit])
      end

      it ".retried returns passed audits with attempts" do
        expect(described_class.retried).to eq([retried_audit])
      end

      it ".stalled returns running audits older than MAX_RUNTIME" do
        expect(described_class.stalled).to eq([running_audit])
      end

      it ".crashed returns failed audits with MAX_ATTEMPTS" do
        expect(described_class.crashed).to eq([crashed_audit])
      end
    end
  end

  describe "#run_at" do
    it "returns the set time when present" do
      time = 1.hour.from_now
      audit.run_at = time
      expect(audit.run_at).to be_within(1.second).of(time)
    end

    it "returns current time when not set" do
      expect(audit.run_at).to be_within(1.second).of(Time.zone.now)
    end
  end

  describe "#due?" do
    it "returns true for pending audits with past run_at" do
      audit.status = "pending"
      audit.run_at = 1.minute.ago
      expect(audit).to be_due
    end

    it "returns false for pending audits with future run_at" do
      audit.status = "pending"
      audit.run_at = 1.minute.from_now
      expect(audit).not_to be_due
    end

    it "returns false for non-pending audits" do
      audit.status = "running"
      audit.run_at = 1.minute.ago
      expect(audit).not_to be_due
    end
  end

  describe "#runnable?" do
    it "returns true when due" do
      allow(audit).to receive(:due?).and_return(true)
      expect(audit).to be_runnable
    end

    it "returns true when retryable" do
      allow(audit).to receive(:retryable?).and_return(true)
      expect(audit).to be_runnable
    end

    it "returns false when neither due nor retryable" do
      allow(audit).to receive(:due?).and_return(false)
      allow(audit).to receive(:retryable?).and_return(false)
      expect(audit).not_to be_runnable
    end
  end

  describe "#parsed_url" do
    it "returns a parsed and normalized URI" do
      audit.url = "https://example.com/path/"
      expect(audit.parsed_url).to be_a(URI::HTTPS)
      expect(audit.parsed_url.to_s).to eq(audit.url)
    end
    # Skip memoization test because framework operation use URI.parse too
  end

  describe "#url_without_scheme" do
    it "returns hostname for root path" do
      audit.url = "https://example.com"
      expect(audit.url_without_scheme).to eq("example.com")
    end

    it "returns hostname and path for non-root path" do
      audit.url = "https://example.com/path"
      expect(audit.url_without_scheme).to eq("example.com/path")
    end

    it "memoizes the result" do
      audit.url = "https://example.com"
      first_result = audit.url_without_scheme
      allow(audit).to receive(:hostname).and_return("different.com")
      expect(audit.url_without_scheme).to eq(first_result)
    end
  end
end
