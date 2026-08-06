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

  describe "enums" do
    it { is_expected.to define_enum_for(:kind).with_values(manual: "manual", csv_import: "csv_import").backed_by_column_of_type(:string) }
  end
end
