require "rails_helper"

RSpec.describe Checks::AccessibilityPageHeading do
  let(:check) { described_class.new }

  describe "#compare_headings" do
    subject(:comparison) { check.send(:compare_headings) }

    let(:expected_headings) { described_class::EXPECTED_HEADINGS }
    let(:page_headings) do
      html = file_fixture("declarations/#{fixture_file_name}.html").read
      Page.new(url: "http://example.com", html:).heading_levels
    end

    before do
      allow(check).to receive(:page_headings).and_return(page_headings)
    end

    context "when the headings are valid" do
      let(:fixture_file_name) { :valid }

      it "returns array of headings with :ok status" do
        expected_result = expected_headings.map.with_index do |(level, heading), index|
          # Skip the first page heading since we start at État de conformité (H2)
          actual_page_heading = page_headings[index + 1].last
          [heading, level, :ok, actual_page_heading]
        end
        expect(comparison).to eq expected_result
      end
    end

    context "when the headings are valid but shifted by one level" do
      let(:fixture_file_name) { :valid_with_shift }

      it "returns :ok status for all headings (ignores start level difference)" do
        expected_result = expected_headings.map.with_index do |(level, heading), index|
          # Skip the first page heading since we start at État de conformité (H2)
          shifted_heading = page_headings[index + 2].last
          [heading, level, :ok, shifted_heading]
        end
        expect(comparison).to eq expected_result
      end
    end

    context "when the headings are invalid" do
      let(:fixture_file_name) { :invalid }

      it "detects all errors documented in HTML comments" do
        expected_result = [
          ["État de conformité", 2, :ok, "État de conformité du site"],
          ["Résultats des tests", 3, :incorrect_level, "Resultat de test"],
          ["Contenus non accessibles", 2, :ok, "Contenu non accessible"],
          ["Non-conformités", 3, :ok, "Non conformite"],
          ["Dérogations pour charge disproportionnée", 3, :missing, nil],
          ["Contenus non soumis à l'obligation d'accessibilité", 3, :ok, "Contenus non soumis à l'obligation d'accessibilité"],
          ["Établissement de cette déclaration d'accessibilité", 2, :ok, "Établissement de cette déclaration d'accessibilité"],
          ["Technologies utilisées pour la réalisation du site", 3, :ok, "Technologies utilisées pour la réalisation de ce service en ligne"],
          ["Environnement de test", 3, :missing, nil],
          ["Outils pour évaluer l'accessibilité", 3, :missing, nil],
          ["Pages du site ayant fait l'objet de la vérification de conformité", 3, :incorrect_level, "Pages du site ayant fait l'objet de la vérification de conformité"],
          ["Retour d'information et contact", 2, :ok, "Retour d'information et contact"],
          ["Voies de recours", 2, :missing, nil]
        ]
        expect(comparison).to eq expected_result
      end
    end
  end

  describe "#heading_statuses" do
    subject(:heading_statuses) { check.heading_statuses }

    before { check.data = comparison_data }

    context "when comparison is empty" do
      let(:comparison_data) { { comparison: [] } }

      it "returns empty array" do
        expect(heading_statuses).to eq []
      end
    end

    context "when comparison has data" do
      let(:comparison_data) do
        {
          comparison: [
            ["État de conformité", 2, :ok, "État de conformité"],
            ["Résultats des tests", 3, :incorrect_level, "Resultat de test"]
          ]
        }
      end

      it "returns array of PageHeadingStatus objects" do
        expect(heading_statuses).to all(be_a(PageHeadingStatus))
        expect(heading_statuses.length).to eq 2
      end

      it "correctly maps comparison data to PageHeadingStatus objects" do
        heading_status = heading_statuses[0]
        expect(heading_status.expected_heading).to eq "État de conformité"
        expect(heading_status.expected_level).to eq 2
        expect(heading_status.status).to eq "ok"
        expect(heading_status.actual_heading).to eq "État de conformité"
        expect(heading_status.ok?).to be true
        expect(heading_status.error?).to be false

        heading_status = heading_statuses[1]
        expect(heading_status.expected_heading).to eq "Résultats des tests"
        expect(heading_status.expected_level).to eq 3
        expect(heading_status.status).to eq "incorrect_level"
        expect(heading_status.actual_heading).to eq "Resultat de test"
        expect(heading_status.ok?).to be false
        expect(heading_status.error?).to be true
      end
    end
  end

  describe "#success_count" do
    subject(:success_count) { check.success_count }

    before { check.data = comparison_data }

    context "when comparison is empty" do
      let(:comparison_data) { { comparison: [] } }

      it "returns 0" do
        expect(success_count).to eq 0
      end
    end

    context "when all headings are correct" do
      let(:comparison_data) do
        {
          comparison: described_class::EXPECTED_HEADINGS.map do |level, heading|
            [heading, level, :ok, heading]
          end
        }
      end

      it "returns total count" do
        expect(success_count).to eq described_class::EXPECTED_HEADINGS.size
      end

      it "has no failures" do
        expect(check.failures.count).to eq 0
      end
    end

    context "when some headings have errors" do
      let(:comparison_data) do
        {
          comparison: [
            ["État de conformité", 2, :ok, "État de conformité"],
            ["Résultats des tests", 3, :incorrect_level, "Résultats des tests"], # error
            *described_class::EXPECTED_HEADINGS[2..-1].map { |level, heading| [heading, level, :missing, nil] }
          ]
        }
      end

      it "returns total minus failures count" do
        expect(success_count).to eq 1
      end

      it "counts failures correctly" do
        expect(check.failures.count).to eq 12
      end
    end
  end
end
