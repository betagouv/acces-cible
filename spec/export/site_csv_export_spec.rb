require "rails_helper"

RSpec.describe SiteCsvExport do
  subject(:parsed_csv) { CSV.parse(export.to_csv, col_sep: ";", headers: true).first }

  let(:team) { create(:team) }
  let(:tags) { ["Gouvernment", "Santé publique"].map { |name| create(:tag, name:, team:) } }
  let(:site) { create(:site, :checked, url: "https://example.com", team:, tags:) }
  let(:export) { described_class.new(Site.where(id: site.id)) }

  describe "#to_csv" do
    it "generates correct data" do
      # Ensure audit data is fresh
      audit = site.audit.reload

      # Clear existing checks and create new ones with proper data using factories
      audit.checks.destroy_all

      reachable = create(:check, :reachable, :completed, audit:, original_url: nil, redirect_url: nil)
      language_indication = create(:check, :language_indication, audit:, indication: "fr")
      accessibility_mention = create(:check, :accessibility_mention, audit:, mention: "partiellement")
      find_accessibility_page = create(:check, :find_accessibility_page, :completed, audit:, url: "https://example.com/accessibilite")
      analyze_accessibility_page = create(:check, :analyze_accessibility_page, audit:, data: {
        compliance_rate: 85.5,
        audit_date: Date.new(2023, 6, 15),
        audit_update_date: Date.new(2025, 8, 20)
      })
      run_axe_on_homepage = create(:check, :run_axe_on_homepage, :completed, audit:, data: {
        passes: 50,
        incomplete: 5,
        inapplicable: 10,
        violations: 3,
        issues_total: 15
      })
      accessibility_page_heading = create(:check, :accessibility_page_heading, :completed, audit:, data: {
        page_headings: [
          [1, "Déclaration d'accessibilité"],
          [2, "État de conformité"],
          [3, "Résultats des tests"]
        ],
        comparison: [
          ["Déclaration d'accessibilité", 1, :ok, "Déclaration d'accessibilité"],
          ["État de conformité", 2, :ok, "État de conformité"],
          ["Résultats des tests", 3, :missing, nil]
        ]
      })

      expected_data = {
        Audit.human(:url) => audit.url,
        Tag.human(:all) => tags.collect(&:name).join(", "),
        Check.human(:completed_at) => audit.completed_at.to_s,
        Checks::Reachable.human(:type) => reachable.completed?.to_s,
        Checks::LanguageIndication.human(:type) => language_indication.indication,
        Checks::AccessibilityMention.human(:type) => accessibility_mention.mention_text,
        Checks::FindAccessibilityPage.human(:type) => find_accessibility_page.url,
        Checks::AnalyzeAccessibilityPage.human(:compliance_rate) => analyze_accessibility_page.human_compliance_rate,
        Checks::AnalyzeAccessibilityPage.human(:audit_date) => analyze_accessibility_page.audit_date.to_s,
        Checks::AnalyzeAccessibilityPage.human(:audit_update_date) => analyze_accessibility_page.audit_update_date.to_s,
        Checks::AccessibilityPageHeading.human(:type) => accessibility_page_heading.human_success_rate,
        Checks::RunAxeOnHomepage.human(:success_rate) => run_axe_on_homepage.human_success_rate
      }

      expect(parsed_csv.to_h).to eq(expected_data)
    end
  end
end
