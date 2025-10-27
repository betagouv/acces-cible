require "rails_helper"

RSpec.describe Checks::AccessibilityPageHeading do
  let(:check) { described_class.new }

  describe "#analyze!" do
    subject(:analyze) { check.send(:analyze!) }

    let(:audit) { create(:audit) }
    let(:fixture_file_name) { :valid }
    let(:page) do
      html = file_fixture("declarations/#{fixture_file_name}.html").read
      Page.new(url: "http://example.com", html:)
    end

    let(:page_headings) { analyze[:page_headings] }
    let(:comparison) { analyze[:comparison] }
    let(:expected_headings) { described_class::EXPECTED_HEADINGS }

    before do
      check.audit = audit
      allow(audit).to receive(:page).with(:accessibility).and_return(page)
    end

    it "returns page_headings and comparison data" do
      expect(page_headings).to eq page.heading_levels
      expect(comparison).to be_an(Array)
    end

    context "when the headings are valid" do
      let(:fixture_file_name) { :valid }

      it "returns array of headings with :ok status" do
        expected_result = expected_headings.map.with_index do |(level, heading), index|
          # Skip the first page heading since we start at État de conformité (H2)
          actual_page_heading = page.heading_levels[index + 1].last
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
          shifted_heading = page.heading_levels[index + 2].last
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

  describe "#score" do
    subject(:score) { check.score }

    before { check.data = comparison_data }

    context "when comparison is empty" do
      let(:comparison_data) { { comparison: [] } }

      it "returns 0" do
        expect(score).to eq 0
      end
    end

    context "when all headings are :ok" do
      let(:comparison_data) do
        {
          comparison: described_class::EXPECTED_HEADINGS.map do |level, heading|
            [heading, level, :ok, heading]
          end
        }
      end

      it "returns 100" do
        expect(score).to eq 100
      end
    end

    context "when all headings are :missing" do
      let(:comparison_data) do
        {
          comparison: described_class::EXPECTED_HEADINGS.map do |level, heading|
            [heading, level, :missing, nil]
          end
        }
      end

      it "returns 0" do
        expect(score).to eq 0
      end
    end

    context "when headings have :incorrect_level" do
      let(:comparison_data) do
        {
          comparison: [
            ["État de conformité", 2, :ok, "État de conformité"],
            ["Résultats des tests", 3, :incorrect_level, "Résultats des tests"],
            *described_class::EXPECTED_HEADINGS[2..-1].map { |level, heading| [heading, level, :ok, heading] }
          ]
        }
      end

      it "applies 50% penalty for incorrect_level (1 ok + 1 incorrect_level + 11 ok = 12.5/13 = 96.15%)" do
        expect(score).to eq 96.15
      end
    end

    context "when headings have :incorrect_order" do
      let(:comparison_data) do
        {
          comparison: [
            ["État de conformité", 2, :ok, "État de conformité"],
            ["Résultats des tests", 3, :incorrect_order, "Résultats des tests"],
            *described_class::EXPECTED_HEADINGS[2..-1].map { |level, heading| [heading, level, :ok, heading] }
          ]
        }
      end

      it "applies 50% penalty for incorrect_order (1 ok + 1 incorrect_order + 11 ok = 12.5/13 = 96.15%)" do
        expect(score).to eq 96.15
      end
    end

    context "when headings have mixed errors" do
      let(:comparison_data) do
        {
          comparison: [
            ["État de conformité", 2, :ok, "État de conformité"],
            ["Résultats des tests", 3, :incorrect_level, "Résultats des tests"],
            ["Contenus non accessibles", 2, :ok, "Contenus non accessibles"],
            ["Non-conformités", 3, :ok, "Non-conformités"],
            ["Dérogations pour charge disproportionnée", 3, :missing, nil],
            ["Contenus non soumis à l'obligation d'accessibilité", 3, :ok, "Contenus non soumis à l'obligation d'accessibilité"],
            ["Établissement de cette déclaration d'accessibilité", 2, :ok, "Établissement de cette déclaration d'accessibilité"],
            ["Technologies utilisées pour la réalisation du site", 3, :ok, "Technologies utilisées pour la réalisation du site"],
            ["Environnement de test", 3, :missing, nil],
            ["Outils pour évaluer l'accessibilité", 3, :missing, nil],
            ["Pages du site ayant fait l'objet de la vérification de conformité", 3, :incorrect_level, "Pages du site ayant fait l'objet de la vérification de conformité"],
            ["Retour d'information et contact", 2, :ok, "Retour d'information et contact"],
            ["Voies de recours", 2, :missing, nil]
          ]
        }
      end

      it "calculates weighted score (7 ok + 2 incorrect_level + 4 missing = 8/13 = 61.54%)" do
        expect(score).to eq 61.54
      end
    end

    context "when half headings are :ok and half are :incorrect_level" do
      let(:comparison_data) do
        {
          comparison: described_class::EXPECTED_HEADINGS.map.with_index do |(level, heading), index|
            status = index.even? ? :ok : :incorrect_level
            [heading, level, status, heading]
          end
        }
      end

      it "returns 75% (7 ok + 6 incorrect_level = 7 + 3 = 10/13 = 76.92%)" do
        expect(score).to eq 76.92
      end
    end
  end
end
