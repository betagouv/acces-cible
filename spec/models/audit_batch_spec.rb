require "rails_helper"

RSpec.describe AuditBatch do
  let(:audit_batch) { create(:audit_batch) }

  describe "#complete?" do
    subject { audit_batch.complete? }

    context "when its audits have not been attached yet" do
      it { is_expected.to be false }
    end

    context "when at least one audit is still pending" do
      before do
        create(:audit, :without_checks, :completed, audit_batch:)
        create(:audit, :without_checks, audit_batch:)
      end

      it { is_expected.to be false }
    end

    context "when every audit is completed" do
      before do
        create(:audit, :without_checks, :completed, audit_batch:)
        create(:audit, :without_checks, :completed, audit_batch:)
      end

      it { is_expected.to be true }
    end
  end

  describe "#progress" do
    subject { audit_batch.progress }

    context "with attached audits" do
      before do
        create(:audit, :without_checks, :completed, audit_batch:)
        create(:audit, :without_checks, audit_batch:)
      end

      it { is_expected.to eq(total: 2, completed: 1) }
    end

    context "when its audits have not been attached yet" do
      it { is_expected.to eq(total: 0, completed: 0) }
    end
  end

  describe "#urls=" do
    subject(:audit_batch) { create(:audit_batch, user:) }

    let(:user) { create(:user) }
    let(:team) { user.team }

    def submit(*urls)
      audit_batch.urls = urls
      audit_batch.save(context: :urls_step)
    end

    it "creates a site and a draft audit" do
      expect(submit("https://example.com")).to be true
      expect(audit_batch.sites.map(&:normalized_url)).to eq(["example.com"])
      expect(audit_batch.audits.map(&:status)).to eq(["draft"])
    end

    it "reuses a site the team already has" do
      existing = create(:site, team:, url: "https://www.example.com")

      expect { submit("https://example.com") }.not_to change(Site, :count)
      expect(audit_batch.sites).to eq([existing])
    end

    it "keeps a single site when the same address is submitted twice" do
      submit("https://example.com", "https://www.example.com/")

      expect(audit_batch.audits.count).to eq(1)
    end

    it "ignores blank entries" do
      submit("https://example.com", "", "  ")

      expect(audit_batch.audits.count).to eq(1)
    end

    it "never rewrites the url of a site that already existed" do
      existing = create(:site, team:, url: "https://existing.example.com")

      submit("https://existing.example.com")
      submit("https://renamed.example.com")

      expect(existing.reload.url).to eq("https://existing.example.com/")
    end

    context "when an address is invalid" do
      it "is rejected and reports the error on the offending site" do
        expect(submit("https://example.com", "pas une adresse")).to be false
        expect(audit_batch.submitted_sites.last.errors[:url]).to be_present
      end

      it "persists nothing, not even the valid addresses" do
        expect { submit("https://example.com", "pas une adresse") }.not_to change(Site, :count)
      end
    end

    context "with more addresses than the maximum" do
      it "is rejected" do
        urls = Array.new(described_class::MAX_SITES + 1) { "https://example-#{it}.com" }

        expect(submit(*urls)).to be false
      end
    end

    context "when an address is removed" do
      before { submit("https://kept.example.com", "https://dropped.example.com") }

      it "destroys its draft audit and the site the funnel had created" do
        expect { submit("https://kept.example.com") }
          .to change(Audit, :count).by(-1)
          .and change(Site, :count).by(-1)

        expect(audit_batch.sites.map(&:normalized_url)).to eq(["kept.example.com"])
      end
    end

    context "when the removed address belongs to a site that already existed" do
      let!(:existing) { create(:site, team:, url: "https://existing.example.com") }

      before { submit("https://existing.example.com") }

      it "detaches it without destroying it" do
        expect { submit("https://other.example.com") }.not_to change { Site.exists?(existing.id) }
      end
    end
  end

  describe "#launch!" do
    subject(:audit_batch) { create(:audit_batch) }

    before do
      create(:audit, :draft, audit_batch:)
      create(:audit, :draft, audit_batch:)
    end

    it "launches the batch and every audit it holds" do
      audit_batch.launch!

      expect(audit_batch).to be_launched
      expect(audit_batch.audits.reload.map(&:status)).to eq(%w[launched launched])
    end
  end

  describe "#abandon!" do
    subject(:audit_batch) { create(:audit_batch, user:) }

    let(:user) { create(:user) }
    let!(:existing) { create(:site, team: user.team, url: "https://existing.example.com") }

    before do
      audit_batch.urls = ["https://existing.example.com", "https://new.example.com"]
      audit_batch.save(context: :urls_step)
    end

    it "destroys the batch, its draft audits and the sites it had created" do
      expect { audit_batch.abandon! }
        .to change(described_class, :count).by(-1)
        .and change(Audit, :count).by(-2)
        .and change(Site, :count).by(-1)

      expect(Site.exists?(existing.id)).to be true
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:kind).with_values(manual: "manual", csv_import: "csv_import").backed_by_column_of_type(:string) }
  end
end
