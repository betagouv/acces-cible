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

  describe "#submitted_sites" do
    subject(:submitted_sites) { build(:audit_batch, user:, urls:).submitted_sites }

    let(:user) { create(:user) }

    context "with blank entries and variants of the same address" do
      let(:urls) { ["https://example.com", "", " https://www.example.com/ "] }

      it "keeps a single unsaved site" do
        expect(submitted_sites.pluck(:url)).to contain_exactly("https://example.com/")
        expect(submitted_sites).to all(be_new_record)
      end
    end
  end

  describe "validations on the urls step" do
    subject(:audit_batch) { build(:audit_batch, :csv_import, user:, file:) }

    let(:user) { create(:user) }
    let(:file) { ActionDispatch::Http::UploadedFile.new(filename: "sites.csv", type: "text/csv", tempfile: file_fixture("sites.csv").open) }

    it "fills the addresses and the tag names from the CSV file" do
      expect(audit_batch.valid?(:urls_step)).to be true
      expect(audit_batch.urls).to eq(["https://example.com/", "https://test.com/"])
      expect(audit_batch.site_tag_names["test.com"]).to eq(["public", "ministère"])
    end

    context "without a file" do
      let(:file) { nil }

      it "requires the file" do
        expect(audit_batch.valid?(:urls_step)).to be false
        expect(audit_batch.errors.added?(:file, :blank)).to be true
      end
    end

    context "with more addresses than the manual limit" do
      subject(:audit_batch) { build(:audit_batch, user:, urls: Array.new(AuditBatch::MAX_MANUAL_SITES + 1) { "https://site-#{it}.example.com" }) }

      it "rejects the batch" do
        expect(audit_batch.valid?(:urls_step)).to be false
        expect(audit_batch.errors.added?(:urls, :too_long, count: AuditBatch::MAX_MANUAL_SITES)).to be true
      end
    end

    context "with addresses already imported" do
      subject(:audit_batch) { build(:audit_batch, :csv_import, user:, urls: ["https://example.com"]) }

      it { is_expected.to be_valid(:urls_step) }
    end
  end

  describe "site tag names" do
    subject(:site_tag_names) { build(:audit_batch, site_tag_names: { "example.com" => ["", "beta"] }).site_tag_names }

    it "ignores the blank value submitted by the form" do
      expect(site_tag_names).to eq("example.com" => ["beta"])
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:kind).with_values(manual: "manual", csv_import: "csv_import").backed_by_column_of_type(:string) }
  end
end
