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
    subject { audit.status_from_checks }

    let(:combined_states) { [] }

    before do
      # FIXME: this isn't great but we haven't made enough progress to
      # factor out the state logic out of the model and mock something
      # else than the subject under test
      allow(audit).to receive(:all_check_states).and_return combined_states # rubocop:disable RSpec/SubjectStub
    end

    context "when some checks are still pending" do
      let(:combined_states) { ["pending", "completed"] }

      it { should eq :pending }
    end

    context "with existing checks of different statuses" do
      let(:combined_states) { ["failed", "completed", "blocked"] }

      it { should eq :mixed }
    end

    context "when all checks have the same status" do
      let(:combined_states) { ["testing"] }

      it { should eq "testing" }
    end
  end

  describe "#update_from_checks" do
    let(:audit) { create(:audit) }

    it "updates status using status_from_checks" do
      allow(audit).to receive_messages(status_from_checks: :mixed)

      audit.update_from_checks
      expect(audit.status).to eq("mixed")
    end

    it "calls set_current_audit! on site when not pending" do
      allow(audit).to receive_messages(status_from_checks: :passed)

      expect(audit.site).to receive(:set_current_audit!)
      audit.update_from_checks
    end

    it "does not call set_current_audit! on site when pending" do
      allow(audit).to receive_messages(status_from_checks: :pending)

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

  describe "after a check has completed" do
    let(:audit) { create(:audit) }

    it "reschedules a ProcessAuditJob with itself" do
      expect { audit.after_check_completed(nil) }.to have_enqueued_job(ProcessAuditJob).with(audit)
    end

    context "when there are no jobs left" do
      before do
        allow(audit.checks).to receive(:remaining).and_return []
      end

      it "does not enqueue a new ProcessAuditJob" do
        expect { audit.after_check_completed(nil) }.not_to enqueue_job(ProcessAuditJob)
      end

      it "updates its checked_at timestamp" do
        freeze_time do
          expect { audit.after_check_completed(nil) }
            .to change(audit, :checked_at)
                  .from(nil)
                  .to(Time.current)
        end
      end
    end
  end

  describe "abort_dependent_checks!" do
    let(:audit) { create(:audit, :without_checks) }

    let(:original_check) { create(:check, :reachable, :failed, audit: audit) }
    let(:dependent_check) { create(:check, :accessibility_mention, :pending, audit: audit) }

    before do
      allow(dependent_check)
        .to receive(:depends_on?)
              .with(original_check.type)
              .and_return true
    end

    it "aborts any check that depends on the failed one" do
      expect { audit.abort_dependent_checks!(original_check) }
        .to change(dependent_check, :current_state)
              .from("pending").to("aborted")
    end
  end
end
