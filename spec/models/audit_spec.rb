require "rails_helper"

RSpec.describe Audit do
  subject(:audit) { build(:audit) }

  let(:site) { audit.site }

  it { is_expected.to be_valid }

  describe "associations" do
    it { is_expected.to belong_to(:site) }
    it { is_expected.to have_many(:checks).dependent(:destroy) }
    it { is_expected.to have_many(:page_snapshots).dependent(:destroy) }
  end

  describe "scopes" do
    before { site.audits.destroy_all }

    it ".sort_by_newest returns audits in descending order by created_at date" do
      oldest = create(:audit, site:, created_at: 3.days.ago)
      older = create(:audit, site:, created_at: 2.days.ago)
      newer = create(:audit, site:, created_at: 1.day.ago)

      expect(described_class.sort_by_newest).to eq([newer, older, oldest])
    end
  end

  describe "#home_page" do
    subject(:home_page) { audit.page_for(:home) }

    let(:site) { create(:site, url: "https://example.com") }
    let(:audit) { create(:audit, :without_checks, site:, home_page_url: site.url) }
    let(:mock_page) { instance_double(Page) }

    context "when a home page snapshot exists" do
      before do
        create(:page_snapshot, audit:, kind: "home", current_url: site.url, html: "<html></html>")
        allow(Page).to receive(:new).and_return(mock_page)
      end

      it "creates a Page with the snapshot's url and html" do
        expect(Page).to receive(:new).with(url: site.url, root: site.url, html: "<html></html>")
        home_page
      end

      it "returns the Page instance" do
        expect(home_page).to eq(mock_page)
      end
    end

    context "when no home page snapshot exists" do
      it "returns nil" do
        expect(home_page).to be_nil
      end
    end
  end

  describe "#accessibility_page" do
    subject(:accessibility_page) { audit.page_for(:accessibility) }

    let(:site) { create(:site, url: "https://example.com") }
    let(:audit) { create(:audit, :without_checks, site:, home_page_url: site.url) }
    let(:mock_page) { instance_double(Page) }
    let(:accessibility_url) { "https://example.com/accessibility" }

    context "when an accessibility page snapshot exists" do
      before do
        create(:page_snapshot, audit:, kind: "accessibility", current_url: accessibility_url, html: "<html></html>")
        allow(Page).to receive(:new).and_return(mock_page)
      end

      it "creates a Page with the accessibility page url" do
        expect(Page).to receive(:new).with(url: accessibility_url, root: site.url, html: "<html></html>")
        accessibility_page
      end

      it "returns the Page instance" do
        expect(accessibility_page).to eq(mock_page)
      end
    end

    context "when no accessibility page snapshot exists" do
      it "returns nil" do
        expect(accessibility_page).to be_nil
      end
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

      it { is_expected.to eq :pending }
    end

    context "with existing checks of different statuses" do
      let(:combined_states) { ["failed", "completed", "blocked"] }

      it { is_expected.to eq :mixed }
    end

    context "when all checks have the same status" do
      let(:combined_states) { ["testing"] }

      it { is_expected.to eq "testing" }
    end

    context "without any check" do
      it { is_expected.to eq :pending }
    end
  end

  describe "#complete?" do
    subject { audit }

    context "without any check" do
      let(:audit) { create(:audit, :without_checks) }

      it { is_expected.not_to be_complete }
    end

    context "with checks left to run" do
      let(:audit) { create(:audit) }

      it { is_expected.not_to be_complete }
    end
  end

  describe "#pending?" do
    subject { audit }

    let(:completed_at) { nil }
    let(:audit) { build(:audit, completed_at: completed_at) }

    context "when audit is not completed" do
      it { is_expected.to be_pending }
    end

    context "when audit is completed" do
      let(:completed_at) { Time.current }

      it { is_expected.not_to be_pending }
    end
  end

  describe "#create_checks" do
    subject(:create_checks) { audit.create_checks }

    let(:audit) { create(:audit, :without_checks) }

    it "creates all check types" do
      expect { create_checks }.to change(Check, :count).by(Check.types.size)
    end
  end

  describe "after_create callback" do
    it "creates checks when audit is created" do
      expect { create(:audit) }.to change(Check, :count).by(Check.types.size)
    end
  end

  describe "a draft audit" do
    subject(:draft) { create(:audit, :draft) }

    it "creates no checks" do
      expect { draft }.not_to change(Check, :count)
    end

    it "enqueues no job" do
      expect { draft }.not_to have_enqueued_job(FetchResourcesJob)
    end

    it "creates its checks once launched" do
      draft
      expect { draft.launched! }.to change(Check, :count).by(Check.types.size)
    end

    it "enqueues its job once launched" do
      draft
      expect { draft.launched! }.to have_enqueued_job(FetchResourcesJob).with(draft).exactly(:once)
    end

    it "does not start again when saved after launching" do
      draft.launched!
      expect { draft.update!(completed_at: Time.current) }.not_to change(Check, :count)
    end
  end

  describe "after a check has completed" do
    let(:audit) { create(:audit) }

    it "reschedules a ProcessAuditJob with itself" do
      expect { audit.after_check_completed }.to have_enqueued_job(ProcessAuditJob).with(audit)
    end

    context "when there are no jobs left" do
      before do
        allow(audit.checks).to receive(:remaining).and_return []
      end

      it "does not enqueue a new ProcessAuditJob" do
        expect { audit.after_check_completed }.not_to enqueue_job(ProcessAuditJob)
      end

      it "updates its completed_at timestamp" do
        freeze_time do
          expect { audit.after_check_completed }
            .to change(audit, :completed_at)
                  .from(nil)
                  .to(Time.current)
        end
      end
    end
  end

  describe "fetch_resources!" do
    let(:audit) { create(:audit) }

    it "triggers the home page fetch" do
      expect { audit.fetch_resources! }
        .to have_enqueued_job(FetchResourcesJob)
              .with(audit)
              .exactly(:once)
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
        .to change { dependent_check.reload.current_state }
              .from("pending").to("aborted")
    end
  end
end
