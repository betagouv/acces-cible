require "rails_helper"

RSpec.describe AuditColumns do
  describe ".value" do
    subject(:value) { described_class.value(Audit.find(audit.id), column) }

    let(:site) { create(:site, :completed, url: "https://example.com") }
    let(:audit) { site.last_audit.tap { it.checks.destroy_all } }
    let(:redirect_url) { nil }
    let!(:reachable) { create(:check, :reachable, :completed, audit:, found: true, data: { redirect_url: }) }

    context "with a reachable site" do
      let(:column) { "reachable" }

      it { is_expected.to include(text: "Oui") }
    end

    context "with an errored reachable check" do
      let!(:reachable) { create(:check, :reachable, :errored, audit:) }

      context "with the reachable column" do
        let(:column) { "reachable" }

        it { is_expected.to include(text: "Non") }
      end

      context "with the redirected column" do
        let(:column) { "redirected" }

        it { is_expected.to eq(described_class::DASH) }
      end
    end

    context "with a pending reachable check" do
      let!(:reachable) { create(:check, :reachable, :pending, audit:) }
      let(:column) { "reachable" }

      it { is_expected.to eq(described_class::DASH) }
    end

    context "with an unreachable site" do
      let!(:reachable) { create(:check, :reachable, :failed, audit:) }
      let!(:dependent_checks) { (Check.names - [:reachable]).map { |type| create(:check, type, :aborted, audit:) } }

      %w[accessibility_page accessibility_mention declared_level compliance_rate schema plan declaration_format legal_obligations automated_tests_result].each do |name|
        context "with the #{name} column" do
          let(:column) { name }

          it { is_expected.to eq(described_class::DASH) }
        end
      end
    end

    context "without a declaration" do
      let!(:find_accessibility_page) { create(:check, :find_accessibility_page, :completed, audit:, found: false) }

      context "with the accessibility_page column" do
        let(:column) { "accessibility_page" }

        it { is_expected.to include(text: "Absent") }
      end

      %w[schema compliance_rate legal_obligations].each do |name|
        context "with the #{name} column" do
          let(:column) { name }

          it { is_expected.to eq(described_class::DASH) }
        end
      end

      context "with completed automated tests" do
        let(:column) { "automated_tests_passed" }
        let!(:run_axe_on_homepage) { create(:check, :run_axe_on_homepage, :completed, audit:, data: { passes: 45, incomplete: 2, inapplicable: 10, violations: 3 }) }

        it { is_expected.to eq(45) }
      end

      context "with skipped automated tests" do
        let(:column) { "automated_tests_passed" }
        let!(:run_axe_on_homepage) { create(:check, :run_axe_on_homepage, :skipped, audit:) }

        it { is_expected.to eq(described_class::DASH) }
      end

      context "with an accessibility mention" do
        let(:column) { "declared_level" }
        let!(:accessibility_mention) { create(:check, :accessibility_mention, :completed, audit:, found: true, conform: true, mention: "totalement") }

        it { is_expected.to include(text: "Totalement conforme") }
      end
    end

    context "with an absent schema" do
      let!(:find_accessibility_page) { create(:check, :find_accessibility_page, :completed, audit:, found: true, url: "https://example.com/accessibilite") }
      let!(:analyze_schema) { create(:check, :analyze_schema, :completed, audit:, found: false) }

      %w[schema_quality schema_url].each do |name|
        context "with the #{name} column" do
          let(:column) { name }

          it { is_expected.to eq(described_class::DASH) }
        end
      end
    end

    context "with an absent plan" do
      let!(:find_accessibility_page) { create(:check, :find_accessibility_page, :completed, audit:, found: true, url: "https://example.com/accessibilite") }
      let!(:analyze_plan) { create(:check, :analyze_plan, :completed, audit:, found: false) }

      %w[plan_quality plan_url].each do |name|
        context "with the #{name} column" do
          let(:column) { name }

          it { is_expected.to eq(described_class::DASH) }
        end
      end
    end
  end
end
