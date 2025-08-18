require "rails_helper"

RSpec.describe SiteCsvExport do
  let(:team) { create(:team) }
  let(:tags) { ["Gouvernment", "Santé publique"].map { |name| create(:tag, name:, team:) } }
  let(:site) { create(:site, url: "https://example.com", team:, tags:) }
  let(:audit) { site.audit }
  let(:export) { described_class.new(Site.where(id: site.id)) }

  describe "#to_csv" do
    let(:csv_content) { export.to_csv }
    let(:lines) { csv_content.split("\n") }
    let(:headers) { lines.first.split(";") }
    let(:data) { lines.last.split(";") }

    it "generates correct headers" do
      expected_headers = [
        Site.human_attribute_name(:url),
        Site.human_attribute_name(:tags),
        Check.human_attribute_name(:checked_at),
        Checks::Reachable.human_attribute_name(:type),
        Checks::LanguageIndication.human_attribute_name(:type),
        Checks::AccessibilityMention.human_attribute_name(:type),
        Checks::FindAccessibilityPage.human_attribute_name(:type),
        Checks::AnalyzeAccessibilityPage.human_attribute_name(:compliance_rate),
        Checks::AnalyzeAccessibilityPage.human_attribute_name(:audit_date),
        Checks::AnalyzeAccessibilityPage.human_attribute_name(:audit_update_date),
        Checks::RunAxeOnHomepage.human_attribute_name(:success_rate),
        Checks::AccessibilityPageHeading.human_attribute_name(:type)
      ]

      expect(headers).to eq(expected_headers)
    end

    it "generates correct data" do
      audit.update(checked_at: 1.day.ago)

      # Update existing checks with factory-like data instead of creating new ones
      audit.reachable.update!(
        data: { original_url: nil, redirect_url: nil }
      )

      audit.language_indication.update!(
        data: { indication: "fr" }
      )

      audit.accessibility_mention.update!(
        data: { mention: "partiellement" }
      )

      audit.find_accessibility_page.update!(
        data: { url: "https://example.com/accessibilite" }
      )

      audit.analyze_accessibility_page.update!(
        data: {
          compliance_rate: 85.5,
          audit_date: Date.new(2023, 6, 15),
          audit_update_date: Date.new(2025, 8, 20)
        }
      )

      audit.run_axe_on_homepage.update!(
        data: {
          passes: 50,
          incomplete: 5,
          inapplicable: 10,
          violations: 3,
          issues_total: 15
        }
      )

      audit.accessibility_page_heading.update!(
        data: {
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
        }
      )

      expect(data[0]).to eq("https://example.com/") # URL
      expect(data[1]).to eq("Gouvernment, Santé publique") # Tags
      expect(data[2]).to include("2025-08-") # Checked at
      expect(data[3]).to eq("true") # Reachable (passed status)
      expect(data[4]).to eq("fr") # Language indication (from factory data)
      expect(data[5]).to eq("Partiellement conforme") # Accessibility mention (from factory data)
      expect(data[6]).to eq("https://example.com/accessibilite") # Accessibility page URL (from factory data)
      expect(data[7]).to eq("85,5%") # Compliance rate (from factory data)
      expect(data[8]).to eq("2023-06-15") # Audit date (from factory data)
      expect(data[9]).to eq("2025-08-20") # Audit update date (from factory data)
      expect(data[10]).to eq("94,83%") # Axe success rate: (50+5)/(50+5+3) * 100 = 94.83%
      expect(data[11]).to eq("13/14") # Accessibility page heading score: based on expected headings count
    end
  end
end
