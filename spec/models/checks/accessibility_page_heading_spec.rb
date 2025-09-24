require "rails_helper"

RSpec.describe Checks::AccessibilityPageHeading do
  let(:check) { described_class.new }

  describe "#compare_headings" do
    subject(:comparison) { check.send(:compare_headings) }

    let(:expected_headings) { described_class::EXPECTED_HEADINGS }
    let(:expected_result) do
      expected_headings.map do |level, heading|
        [heading, level, :ok, heading]
      end
    end
    let(:page_headings) { expected_headings }

    before do
      allow(check).to receive(:page_headings).and_return(page_headings)
    end

    context "when all expectations are met" do
      it "returns array of headings with :ok status" do
        expect(comparison).to eq expected_result
      end
    end

    context "when all expectations are met, but an extra heading increases the level by 1" do
      let(:page_headings) do
        [[1, "Accessibilité"]] + expected_headings.map do |level, heading|
          [level + 1, heading]
        end
      end

      it "returns :ok status for all headings (ignores start level difference)" do
        expect(comparison).to eq expected_result
      end
    end

    context "when the first heading doesn't match, but all following do" do
      let(:page_headings) do
        expected_headings.each_with_index.map do |(level, heading), index|
          index.zero? ? [level, "Rien à voir"] : [level, heading]
        end
      end

      it "returns :ok status for all headings but the first" do
        expected_result = expected_headings.each_with_index.map do |(level, heading), index|
          index.zero? ? [heading, level, :missing, nil] : [heading, level, :ok, heading]
        end
        expect(comparison).to eq expected_result
      end
    end

    context "when page headings match with slight differences" do
      let(:page_headings) do
        [
          [1, "DECLARATION d'accessibilité"], # Different case
          [2, "État de conformité"],
          [3, "Resultat de test"],     # Typos
          [2, "Contenu non accessible"],  # Singular vs plural
          [3, "Non conformite"],  # Missing hyphen and accent
        ]
      end

      it "returns :ok status for all (ignores case differences, extra text and typos)" do
        expected_result = expected_headings.each_with_index.map do |(level, heading), index|
          if index < page_headings.size
            [heading, level, :ok, page_headings[index][1]]
          else
            [heading, level, :missing, nil]
          end
        end
        expect(comparison).to eq expected_result
      end
    end

    context "when some headings are missing from the page" do
      let(:page_headings) do
        [
          [1, "Déclaration d'accessibilité"],
          [2, "État de conformité"],
          [3, "Résultats des tests"],
        ]
      end

      it "returns :missing status for missing headings" do
        expected_result = expected_headings.map.with_index do |(level, heading), index|
          if index < page_headings.size
            [heading, level, :ok, page_headings[index][1]]
          else
            [heading, level, :missing, nil]
          end
        end
        expect(comparison).to eq expected_result
      end
    end

    context "when headings are swapped" do
      let(:page_headings) { expected_headings.reverse }

      it "returns :incorrect_order status for out-of-order headings" do
        expected_result = expected_headings.map.with_index do |(level, heading), index|
          index.zero? ? [heading, level, :ok, heading] : [heading, level, :incorrect_order, heading]
        end
        expect(comparison).to eq expected_result
      end
    end

    context "when some page headings are incorrectly nested" do
      let(:page_headings) do
        [
          [1, "Déclaration d'accessibilité"],
          [2, "État de conformité"],
          [2, "Résultats des tests"],     # instead of 3
          [4, "Contenus non accessibles"], # instead of 2
          [3, "Non-conformités"],
          [3, "Dérogations pour charge disproportionnée"],
          [3, "Contenus non soumis à l'obligation d'accessibilité "],
          [2, "Établissement de cette déclaration d'accessibilité"],
          [3, "Technologies utilisées pour la réalisation du site"],
          [3, "Environnement de test"],
          [3, "Outils pour évaluer l'accessibilité"],
          [3, "Pages du site ayant fait l'objet de la vérification de conformité"],
          [2, "Retour d'information et contact"],
          [2, "Voies de recours"],
        ]
      end

      it "returns :incorrect_level status for headings with incorrect nesting" do
        expected_result = expected_headings.map.with_index do |(level, heading), index|
          if index == 2 || index == 3
            [heading, level, :incorrect_level, heading]
          else
            [heading, level, :ok, heading]
          end
        end
        expect(comparison).to eq expected_result
      end
    end

    context "with a mix of correct, missing, and incorrectly nested headings" do
      let(:page_headings) do
        [
          [1, "Déclaration d'accessibilité"],
          [2, "État de conformité"],
          [2, "Résultats des tests"],           # incorrect level
          [3, "Technologies de test"],           # incorrect text, this won't match any expected heading
          # Missing remaining headings
        ]
      end

      it "correctly identifies all types of issues" do
        expected_result = expected_headings.map.with_index do |(level, heading), index|
          case index
          when 0, 1
            [heading, level, :ok, heading]
          when 2
            [heading, level, :incorrect_level, page_headings[index][1]]
          else
            [heading, level, :missing, nil]
          end
        end
        expect(comparison).to eq expected_result
      end
    end
  end

  describe "#success_count" do
    subject(:success_count) { check.success_count }

    before { check.data = comparison_data }

    context "when comparison is empty" do
      let(:comparison_data) { {} }

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
        expect(success_count).to eq 14
      end
    end

    context "when some headings have errors" do
      let(:comparison_data) do
        {
          comparison: [
            ["Déclaration d'accessibilité", 1, :ok, "Déclaration d'accessibilité"],
            ["État de conformité", 2, :ok, "État de conformité"],
            ["Résultats des tests", 3, :incorrect_level, "Résultats des tests"], # error
            *described_class::EXPECTED_HEADINGS[3..-1].map { |level, heading| [heading, level, :missing, nil] }
          ]
        }
      end

      it "returns total minus failures count" do
        expect(success_count).to eq 2
      end
    end
  end
end
