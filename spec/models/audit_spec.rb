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

  describe "scopes" do
    before { site.audit.destroy }

    it ".sort_by_newest returns audits in descending order by created_at date" do
      oldest = create(:audit, site:, created_at: 3.days.ago)
      older = create(:audit, site:, created_at: 2.days.ago)
      newer = create(:audit, site:, created_at: 1.day.ago)

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

    it "caches built checks in instance variables" do
      audit = build(:audit)
      audit.all_checks

      Check.types.each do |name, klass|
        expect(audit.instance_variable_get("@#{name}")).to be_present
        expect(audit.instance_variable_get("@#{name}")).to be_a(klass)
      end
    end
  end

  describe "#page" do
    subject(:page) { audit.page(kind) }

    let(:audit) { create(:audit, :without_checks, url: "https://example.com") }
    let(:mock_page) { instance_double(Page, html: nil) }

    before do
      allow(Page).to receive(:new).and_return(mock_page)
    end

    context "when kind is :home" do
      let(:kind) { :home }

      it "creates a Page with the audit url" do
        expect(Page).to receive(:new).with(url: audit.url, root: audit.url, html: nil)
        page
      end

      it "returns the Page instance" do
        expect(page).to eq(mock_page)
      end
    end

    context "when kind is :accessibility" do
      let(:kind) { :accessibility }

      context "when find_accessibility_page check has a url" do
        let(:check) { instance_double(Checks::FindAccessibilityPage, url: "#{audit.url}/accessibilite") }

        before do
          allow(audit).to receive(:find_accessibility_page).and_return(check)
        end

        it "creates a Page with the accessibility page url" do
          expect(Page).to receive(:new).with(url: "#{audit.url}/accessibilite", root: audit.url, html: nil)
          page
        end

        it "returns the Page instance" do
          expect(page).to eq(mock_page)
        end
      end

      context "when find_accessibility_page check has no url" do
        let(:check) { instance_double(Checks::FindAccessibilityPage, url: nil) }

        before do
          allow(audit).to receive(:find_accessibility_page).and_return(check)
        end

        it "returns nil" do
          expect(page).to be_nil
        end
      end

      context "when find_accessibility_page check does not exist" do
        before do
          allow(audit).to receive(:find_accessibility_page).and_return(nil)
        end

        it "returns nil" do
          expect(page).to be_nil
        end
      end
    end

    context "when kind is nil" do
      let(:kind) { nil }

      it "raises an ArgumentError" do
        expect { page }.to raise_error(ArgumentError, /Don't know how to find a page of kind ''/)
      end
    end

    context "when kind is unrecognised" do
      let(:kind) { :hmoe }

      it "raises an ArgumentError" do
        expect { page }.to raise_error(ArgumentError, /Don't know how to find a page of kind 'hmoe'/)
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

  describe "#pending?" do
    subject { audit }

    let(:checked_at) { nil }
    let(:audit) { build(:audit, checked_at: checked_at) }

    context "when audit is not completed" do
      it { should be_pending }
    end

    context "when audit is completed" do
      let(:checked_at) { Time.current }

      it { should_not be_pending }
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
      expect { audit.after_check_completed }.to have_enqueued_job(ProcessAuditJob).with(audit)
    end

    context "when there are no jobs left" do
      before do
        allow(audit.checks).to receive(:remaining).and_return []
      end

      it "does not enqueue a new ProcessAuditJob" do
        expect { audit.after_check_completed }.not_to enqueue_job(ProcessAuditJob)
      end

      it "updates its checked_at timestamp" do
        freeze_time do
          expect { audit.after_check_completed }
            .to change(audit, :checked_at)
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

  describe "update_home_page!" do
    let(:url) { "https://example.com" }
    let(:html) { "html_content" }

    it "updates the home page HTML" do
      expect { audit.update_home_page!(url, html) }
        .to change(audit, :home_page_html).from(nil).to(html)
                                          .and change(audit, :home_page_url).from(nil).to(url)
    end
  end
end
