require "rails_helper"

RSpec.describe SiteCsvExport do
  let(:team) { create(:team) }
  let(:tags) { ["Gouvernment", "Santé publique"].map { |name| create(:tag, name:, team:) } }
  let(:site) { create(:site, :checked, url: "https://example.com", team:, tags:) }

  describe ".filename" do
    it "generates filename with current date" do
      travel_to Time.zone.local(2024, 3, 15, 10, 30) do
        expect(described_class.filename).to match(/^sites_.*\.csv$/)
      end
    end
  end

  describe ".stream_csv_to" do
    subject(:parsed_csv) { CSV.parse(csv_output, col_sep: ";", headers: true) }

    let(:csv_output) do
      output = StringIO.new
      described_class.stream_csv_to(output, Site.where(id: site.id))
      output.string
    end

    context "with completed checks" do
      before do
        audit = site.audit.reload
        audit.checks.destroy_all

        create(:check, :reachable, :completed, audit:)
        create(:check, :language_indication, audit:, indication: nil)
        create(:check, :accessibility_mention, :completed, audit:, mention: "totalement")
        create(:check, :find_accessibility_page, :completed, audit:, url: "https://example.com/accessibilite")
        create(:check, :analyze_accessibility_page, audit:, data: {
          compliance_rate: 85.5,
          audit_date: Date.new(2023, 6, 15),
          audit_update_date: Date.new(2025, 8, 20),
          auditor: "Bear & Bee"
        })
        create(:check, :analyze_schema, audit:, data: {
          link_url: "https://example.com/schema.pdf", years: [2023, 2024]
        })
        create(:check, :analyze_plan, audit:, data: {
          link_url: "https://example.com/plan.pdf", years: [2025]
        })
        create(:check, :run_axe_on_homepage, :completed, audit:, data: {
          passes: 45,
          incomplete: 2,
          inapplicable: 10,
          violations: 3,
        })
        create(:check, :accessibility_page_heading, :completed, audit:, data: {
          page_headings: [
            [1, "Déclaration d'accessibilité"]
          ],
          comparison: [
            ["Déclaration d'accessibilité", 1, :ok, "Déclaration d'accessibilité"]
          ]
        })
      end

      it "includes headers" do
        expect(parsed_csv.headers).to eq([
                                           "Adresse du site",
                                           "URL",
                                           "URL de redirection",
                                           "Toutes les étiquettes",
                                           "Vérification effectuée le",
                                           "Site joignable",
                                           "Indication de la langue",
                                           "Mention du niveau d'accessibilité",
                                           "Présence d'une déclaration d'accessibilité",
                                           "Audit réalisé par",
                                           "Taux de conformité",
                                           "Date de la déclaration",
                                           "Déclaration mise à jour le",
                                           "Schéma pluriannuel d'accessibilité",
                                           "Années de validité du schéma",
                                           "Plan d'action",
                                           "Année(s) du plan",
                                           "Titres de la déclaration d'accessibilité",
                                           "Taux de réussite"
                                         ])
      end

      it "generates correct row data" do
        row = parsed_csv.first
        audit = site.audit.reload

        expect(row["Adresse du site"]).to eq(site.url_without_scheme_and_www)
        expect(row["URL"]).to eq(audit.url)
        expect(row["URL de redirection"]).to be_nil
        expect(row["Toutes les étiquettes"]).to eq(tags.collect(&:name).join(", "))
        expect(row["Vérification effectuée le"]).to eq(audit.checked_at.to_s)
        expect(row["Site joignable"]).to eq("true")
        expect(row["Indication de la langue"]).to eq("Non trouvé")
        expect(row["Mention du niveau d'accessibilité"]).to eq("Totalement conforme")
        expect(row["Présence d'une déclaration d'accessibilité"]).to eq("https://example.com/accessibilite")
        expect(row["Audit réalisé par"]).to eq("Bear & Bee")
        expect(row["Taux de conformité"]).to eq("85,5%")
        expect(row["Date de la déclaration"]).to eq("2023-06-15")
        expect(row["Déclaration mise à jour le"]).to eq("2025-08-20")
        expect(row["Schéma pluriannuel d'accessibilité"]).to eq("https://example.com/schema.pdf")
        expect(row["Années de validité du schéma"]).to eq("2023-2024")
        expect(row["Plan d'action"]).to eq("https://example.com/plan.pdf")
        expect(row["Année(s) du plan"]).to eq("2025")
      end
    end

    context "with failed check" do
      before do
        audit = site.audit.reload
        audit.checks.destroy_all

        create(:check, :reachable, :failed, audit:)
      end

      it "shows human_status for failed check" do
        row = parsed_csv.first
        expect(row["Indication de la langue"]).to eq("Non trouvé")
      end
    end

    context "with errored check" do
      before do
        audit = site.audit.reload
        audit.checks.destroy_all

        create(:check, :accessibility_mention, :errored, audit:)
      end

      it "shows human_status for errored check" do
        row = parsed_csv.first
        expect(row["Mention du niveau d'accessibilité"]).to eq("Erreur")
      end
    end

    context "with aborted check" do
      before do
        audit = site.audit.reload
        audit.checks.destroy_all

        create(:check, :accessibility_mention, :aborted, audit:)
      end

      it "shows human_status for aborted check" do
        row = parsed_csv.first
        expect(row["Mention du niveau d'accessibilité"]).to eq("Annulé")
      end
    end
  end

  describe ".extract_value" do
    let(:check) { instance_double(Check) }

    context "when check is nil" do
      it "returns not found" do
        expect(described_class.extract_value(nil, nil)).to eq("Non trouvé")
      end
    end

    context "when check is aborted" do
      before do
        allow(check).to receive_messages(aborted?: true, errored?: false, failed?: false, human_status: "Aborted")
      end

      it "returns human_status" do
        expect(described_class.extract_value(check, "something")).to eq("Aborted")
      end
    end

    context "when check is completed" do
      before do
        allow(check).to receive_messages(aborted?: false, errored?: false, failed?: false)
      end

      it "yields and returns block value" do
        expect(described_class.extract_value(check, "something")).to eq("something")
      end
    end
  end
end
