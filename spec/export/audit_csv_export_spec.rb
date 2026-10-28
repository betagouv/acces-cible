require "rails_helper"

RSpec.describe AuditCsvExport do
  let(:team) { create(:team) }
  let(:tags) { ["Gouvernment", "Santé publique"].map { |name| create(:tag, name:, team:) } }
  let(:site) { create(:site, :completed, url: "https://example.com", team:, tags:) }
  let(:csv_without_bom) { csv_output.delete_prefix(described_class::UTF8_BOM) }

  describe ".filename" do
    it "generates filename with current date" do
      travel_to Time.zone.local(2024, 3, 15, 10, 30) do
        expect(described_class.filename).to match(/^audits_.*\.csv$/)
      end
    end
  end

  describe ".stream_csv_to" do
    subject(:parsed_csv) { CSV.parse(csv_without_bom, col_sep: ";", headers: true) }

    let(:csv_output) do
      io = StringIO.new
      described_class.stream_csv_to(io, site.reload.audits)
      io.string
    end

    it "prefixes the CSV with a UTF-8 BOM" do
      expect(csv_output).to start_with(described_class::UTF8_BOM)
    end

    it "includes headers" do
      expect(parsed_csv.headers).to eq([
                                         "Site",
                                         "Url évaluée",
                                         "Site joignable",
                                         "Site en redirection",
                                         "Url de redirection",
                                         "Déclaration d'accessibilité",
                                         "URL de la déclaration",
                                         "Hébergement de la déclaration",
                                         "Taux d'accessibilité déclaré (évaluation)",
                                         "Taux d'accessibilité déclaré",
                                         "Mention d'accessibilité",
                                         "Niveau d'accessibilité déclaré",
                                         "Schéma pluriannuel (évaluation)",
                                         "Schéma pluriannuel (lien)",
                                         "Schéma pluriannuel (qualité)",
                                         "Plan d'action",
                                         "Plan d'action (lien)",
                                         "Plan d'action (qualité)",
                                         "Date de déclaration (évaluation)",
                                         "Date de déclaration",
                                         "Référentiel (évaluation)",
                                         "Référentiel",
                                         "Auditeur (évaluation)",
                                         "Auditeur",
                                         "Article de loi",
                                         "Adresse email de contact (ou formulaire de contact) (évaluation)",
                                         "Adresse email",
                                         "Formulaire de contact",
                                         "Titres de la déclaration d'accessibilité (évaluation)",
                                         "Respect des obligations légales (note /4)",
                                         "Qualité de la déclaration (note /4)",
                                         "Résultat des tests auto RGAA",
                                         "Tests auto RGAA applicables",
                                         "Tests auto RGAA réussis",
                                         "Tests auto non applicables",
                                         "Évaluateur",
                                         "Organisation",
                                         "Étiquettes",
                                         "Lancée le",
                                         "URL évaluation accès cible"
                                       ])
    end

    context "with completed checks" do
      before do
        audit = site.last_audit.reload
        audit.checks.destroy_all

        create(:check, :reachable, :completed, audit:, found: true, data: { redirect_url: "https://www.example.com/" })
        create(:check, :accessibility_mention, :completed, audit:, found: true, conform: true, mention: "totalement")
        create(:check, :find_accessibility_page, :completed, audit:, url: "https://example.com/accessibilite", internal: true, conform: true)
        create(:check, :analyze_accessibility_page, :completed, audit:, data: {
          compliance_rate: 85.5,
          audit_date: Date.new(2023, 6, 15),
          audit_update_date: Date.new(2025, 8, 20),
          auditor: "Bear & Bee",
          contact_form: "https://example.com/contact"
        })
        create(:check, :analyze_schema, :completed, audit:, found: true, conform: true, data: {
          link_url: "https://example.com/schema.pdf", years: [2023, 2024]
        })
        create(:check, :analyze_plan, :completed, audit:, found: true, conform: false, data: {
          link_url: "https://example.com/plan.pdf", years: [2025]
        })
        create(:check, :run_axe_on_homepage, :completed, audit:, data: {
          passes: 45,
          incomplete: 2,
          inapplicable: 10,
          violations: 3,
        })
        create(:check, :accessibility_page_heading, :completed, audit:, found: true, data: {
          page_headings: [
            [1, "Déclaration d'accessibilité"]
          ],
          comparison: [
            ["Déclaration d'accessibilité", 1, :ok, "Déclaration d'accessibilité"]
          ]
        })
        audit.update_columns(legal_obligation_score: 3, declaration_quality_score: 2.5)
      end

      it "generates correct row data" do
        row = parsed_csv.first
        audit = site.last_audit.reload

        expect(row.to_h).to eq(
                              "Site" => "example.com",
                              "Site joignable" => "Oui",
                              "Site en redirection" => "Non",
                              "Url évaluée" => "https://example.com/",
                              "Url de redirection" => "https://www.example.com/",
                              "Taux d'accessibilité déclaré (évaluation)" => "Présent",
                              "Taux d'accessibilité déclaré" => "85,5%",
                              "Niveau d'accessibilité déclaré" => "Totalement conforme",
                              "Respect des obligations légales (note /4)" => "3",
                              "Déclaration d'accessibilité" => "Présent",
                              "URL de la déclaration" => "https://example.com/accessibilite",
                              "Mention d'accessibilité" => "Présent",
                              "Schéma pluriannuel (évaluation)" => "Présent",
                              "Schéma pluriannuel (lien)" => "https://example.com/schema.pdf",
                              "Plan d'action" => "Présent",
                              "Plan d'action (lien)" => "https://example.com/plan.pdf",
                              "Qualité de la déclaration (note /4)" => "2.5",
                              "Hébergement de la déclaration" => "Valide",
                              "Date de déclaration (évaluation)" => "Présent",
                              "Date de déclaration" => I18n.l(Date.new(2023, 6, 15)),
                              "Référentiel (évaluation)" => "Absent",
                              "Référentiel" => "-",
                              "Auditeur (évaluation)" => "Présent",
                              "Auditeur" => "Bear & Bee",
                              "Article de loi" => "Absent",
                              "Adresse email de contact (ou formulaire de contact) (évaluation)" => "Présent",
                              "Adresse email" => "-",
                              "Formulaire de contact" => "https://example.com/contact",
                              "Titres de la déclaration d'accessibilité (évaluation)" => "Invalide",
                              "Schéma pluriannuel (qualité)" => "Valide",
                              "Plan d'action (qualité)" => "Invalide",
                              "Résultat des tests auto RGAA" => "45 / 50 réussis",
                              "Tests auto RGAA applicables" => "50",
                              "Tests auto RGAA réussis" => "45",
                              "Tests auto non applicables" => "10",
                              "URL évaluation accès cible" => "http://example.com/sites/example-com/audits/#{audit.id}",
                              "Évaluateur" => audit.user.to_s,
                              "Organisation" => "-",
                              "Lancée le" => I18n.l(audit.created_at.to_datetime, format: :complete),
                              "Étiquettes" => "Gouvernment, Santé publique"
                            )
      end

      it "marks an externally hosted declaration as invalid" do
        site.last_audit.reload.find_accessibility_page.update!(internal: false, conform: false)

        expect(parsed_csv.first["Hébergement de la déclaration"]).to eq("Invalide")
      end
    end
  end
end
