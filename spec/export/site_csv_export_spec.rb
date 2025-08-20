require "rails_helper"

RSpec.describe SiteCsvExport do
  let(:team) { create(:team) }
  let(:tags) { ["Gouvernment", "Santé publique"].map { |name| create(:tag, name:, team:) } }
  let(:site) { create(:site, :checked, url: "https://example.com", team:, tags:) }
  let(:export) { described_class.new(Site.where(id: site.id)) }

  describe "#to_csv" do
    let(:csv_content) { export.to_csv }
    let(:lines) { csv_content.split("\n") }
    let(:headers) { lines.first.split(";") }
    let(:data) { lines.last.split(";") }

    it "generates correct headers" do
      expected_headers = [
        Audit.human(:url),
        Tag.human(:all),
        Check.human(:checked_at),
        Checks::Reachable.human(:type),
        Checks::LanguageIndication.human(:type),
        Checks::AccessibilityMention.human(:type),
        Checks::FindAccessibilityPage.human(:type),
        Checks::AnalyzeAccessibilityPage.human(:compliance_rate),
        Checks::AnalyzeAccessibilityPage.human(:audit_date),
        Checks::AnalyzeAccessibilityPage.human(:audit_update_date),
        Checks::AccessibilityPageHeading.human(:type),
        Checks::RunAxeOnHomepage.human(:success_rate)
      ]

      expect(headers).to eq(expected_headers)
    end

    it "generates correct data" do
      # Ensure audit data is fresh
      audit = site.audit.reload

      # Clear existing checks and create new ones with proper data using factories
      audit.checks.destroy_all

      reachable = create(:check, :reachable, :completed, audit:, data: { original_url: nil, redirect_url: nil })
      language_indication = create(:check, :language_indication, audit:, data: { indication: "fr" })
      accessibility_mention = create(:check, :accessibility_mention, audit:, data: { mention: "partiellement" })
      find_accessibility_page = create(:check, :find_accessibility_page, :completed, audit:, data: { url: "https://example.com/accessibilite" })
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

      expect(data[0]).to eq(audit.url)
      expect(data[1]).to eq(tags.collect(&:name).join(", "))
      expect(data[2].to_date).to eq(audit.checked_at.to_date)
      expect(data[3]).to eq(reachable.completed?.to_s)
      expect(data[4]).to eq(language_indication.indication)
      expect(data[5]).to eq(accessibility_mention.mention_text)
      expect(data[6]).to eq(find_accessibility_page.url)
      expect(data[7]).to eq(analyze_accessibility_page.human_compliance_rate)
      expect(data[8]).to eq(analyze_accessibility_page.audit_date.to_s)
      expect(data[9]).to eq(analyze_accessibility_page.audit_update_date.to_s)
      expect(data[10]).to eq(accessibility_page_heading.human_success_rate)
      expect(data[11]).to eq(run_axe_on_homepage.human_success_rate)
    end
  end
end
