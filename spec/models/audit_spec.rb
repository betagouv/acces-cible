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

    context "when audit is not scheduled" do
      before { audit.update!(scheduled: false) }

      it "marks audit as scheduled and enqueues RunAuditJob" do
        expect { schedule }.to change(audit, :scheduled).from(false).to(true)
                               .and have_enqueued_job(RunAuditJob).with(audit)
      end
    end

    context "when audit is already scheduled" do
      before { audit.update!(scheduled: true) }

      it "does not mark audit as scheduled" do
        expect { schedule }.not_to change(audit, :scheduled)
      end

      it "does not enqueue RunAuditJob" do
        expect { schedule }.not_to have_enqueued_job(RunAuditJob)
      end
    end
  end

  describe "#derive_status_from_checks" do
    let(:audit) { build(:audit) }

    it "sets status to pending when any check is new" do
      audit = build(:audit)
      audit.derive_status_from_checks
      expect(audit.status).to eq("pending")
    end

    it "sets status to mixed when checks have different statuses" do
      audit.all_checks.each { |check| check.passed!; check.save }
      audit.checks.last.update!(status: :failed)
      audit.derive_status_from_checks
      expect(audit.status).to eq("mixed")
    end

    it "sets status to match checks when all have same status" do
      audit.all_checks.each { |check| check.update(status: :passed) }
      audit.derive_status_from_checks
      expect(audit.status).to eq("passed")
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
