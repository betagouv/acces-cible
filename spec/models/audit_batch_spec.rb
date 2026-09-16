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
        expect(submitted_sites.map(&:url)).to eq(["https://example.com/"])
        expect(submitted_sites).to all(be_new_record)
      end
    end

    context "with an address the team already has" do
      let!(:site) { create(:site, team: user.team, url: "https://example.com") }
      let(:urls) { ["https://www.example.com"] }

      it { is_expected.to eq([site]) }
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:kind).with_values(manual: "manual", csv_import: "csv_import").backed_by_column_of_type(:string) }
  end
end
