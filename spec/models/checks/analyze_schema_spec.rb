require "rails_helper"

RSpec.describe Checks::AnalyzeSchema do
  let(:check) { described_class.send(:new) }

  describe ".analyze!" do
    subject(:analyze) { check.send(:analyze!) }

    context "when there is no accessibility page" do
      it "returns nil" do
        allow(check).to receive(:page).and_return(nil)

        expect(analyze).to be_nil
      end
    end

    context "when find_link returns nil" do
      it "returns nil" do
        page = build(:page, html: "<html><body></body></html>")
        allow(check).to receive_messages(page:, find_link: nil)

        expect(analyze).to be_nil
      end
    end

    context "when a link is found" do
      let(:year) { Time.current.year }

      it "returns a hash containing link_url, link_text, years, reachable, and valid_years" do
        page = build(:page, html: "<html><body></body></html>")
        link = Link.new(href: "schema_pluriannuel.pdf", text: "Schéma pluriannuel d'accessibilité #{year - 1}-#{year + 1}")
        allow(check).to receive_messages(page:, find_link: link)
        allow(Browser).to receive(:exists?).with(link.href).and_return(true)

        expect(analyze).to include(
          link_url: link.href,
          link_text: link.text,
          years: [year - 1, year + 1],
          reachable: true,
          valid_years: true
        )
      end
    end
  end

  describe "#find_link" do
    subject(:find_link) { check.find_link }

    let(:page) { build(:page, links:) }

    before { allow(check).to receive(:page).and_return(page) }

    context "when link text matches pattern" do
      [
        "Schéma pluriannuel RGAA",
        "Schema pluriannuel RGAA",
        "Schéma d'accessibilité numérique",
        "schéma pluriannuel d’accessibilité",
        "Schéma pluriannuel d'accessibilité",
        "Télécharger le schéma pluri-annuel d'accessibilité (PDF, 169.31 Ko)",
        "Schéma pluriannuel d'accessibilité numérique",
        "Schéma pluriannuel de l'accessibilité numérique",
        "Schéma pluriannuel de l'accessibilité",
        "Schéma pluriannuel de mise en accessibilité",
        "Schéma pluriannuel de mise en accessibilité numérique",
        "Schéma annuel d'accessibilité",
        "SCHEMA PLURIANNUEL D'ACCESSIBILITE NUMERIQUE",
        "Schéma pluriannuel d'accessibilité 2024",
        "SCHEMA PLURIANNUEL D'ACCESSIBILITE NUMERIQUE 2024-2026",
        "Accessibilité numérique — Schéma annuel",
      ].each do |text|
        context "with '#{text}'" do
          let(:links) { [text] }

          it "finds the link" do
            expect(find_link.text).to eq(text)
          end
        end
      end
    end

    context "when link text does not match pattern" do
      [
        "Plan d'accessibilité",
        "Déclaration d'accessibilité",
        "Accessibilité",
        "Documentation",
        "Schéma directeur",
      ].each do |text|
        context "with '#{text}'" do
          let(:links) { [text] }

          it "returns nil" do
            expect(find_link).to be_nil
          end
        end
      end
    end

    context "when multiple links match pattern" do
      let(:links) do
        [
          "Schéma pluriannuel d'accessibilité 2020-2022",
          "Schéma pluriannuel d'accessibilité 2023-2025",
          "Schéma pluriannuel d'accessibilité 2021",
        ]
      end

      it "returns the link with the highest years" do
        expect(find_link.text).to eq("Schéma pluriannuel d'accessibilité 2023-2025")
      end
    end
  end

  describe "#extract_years" do
    {
      "Schéma pluriannuel d'accessibilité" => [],
      "Schéma pluriannuel d'accessibilité 2024" => [2024],
      "SCHEMA PLURIANNUEL D'ACCESSIBILITE NUMERIQUE 2023-2025" => [2023, 2025],
      "SCHEMA PLURIANNUEL D'ACCESSIBILITE NUMERIQUE 2025-2023" => [2023, 2025],
    }.each do |text, expected_result|
      it "extracts #{expected_result} from '#{text}'" do
        expect(check.send(:extract_years, text)).to eq(expected_result)
      end
    end
  end

  describe "#validate_years" do
    current_year = Date.current.year
    last_year = current_year - 1
    next_year = current_year + 1
    max_year_distance = described_class::MAX_YEARS_VALIDITY
    min_year = current_year - max_year_distance
    max_year = current_year + max_year_distance

    {
      [current_year] => true,
      [last_year] => false,
      [next_year] => false,
      [min_year, current_year] => true,
      [current_year, max_year] => true,
      [last_year, next_year] => true,
      [min_year - 1, last_year] => false,
      [next_year, max_year + 1] => false,
    }.each do |years, expected_result|
      it "returns #{expected_result} for #{years}" do
        expect(check.send(:validate_years, years)).to eq(expected_result)
      end
    end
  end

  describe "#custom_badge_status" do
    subject(:custom_badge_status) { check.custom_badge_status }

    context "when all passed" do
      it "returns success" do
        allow(check).to receive_messages(link_url: "url", valid_years: true, reachable: true)

        expect(custom_badge_status).to eq(:success)
      end
    end

    context "when link is valid but years are invalid" do
      it "returns warning" do
        allow(check).to receive_messages(link_url: "url", valid_years: false, reachable: true)

        expect(custom_badge_status).to eq(:warning)
      end
    end

    context "when link is not found" do
      it "returns error" do
        allow(check).to receive_messages(link_url: nil, valid_years: false, reachable: false)

        expect(custom_badge_status).to eq(:error)
      end
    end
  end

  describe "#custom_badge_text" do
    subject(:custom_badge_text) { check.custom_badge_text }

    context "when all passed" do
      it "returns human(:all_passed)" do
        allow(check).to receive_messages(link_url: "url", valid_years: true, reachable: true)

        expect(custom_badge_text).to eq(check.human(:all_passed))
      end
    end

    context "when link is valid but years are invalid" do
      it "returns human(:invalid_years)" do
        allow(check).to receive_messages(link_url: "url", valid_years: false, reachable: true)

        expect(custom_badge_text).to eq(check.human(:invalid_years))
      end
    end

    context "when link is not found" do
      it "returns human(:link_not_found)" do
        allow(check).to receive_messages(link_url: nil, valid_years: false, reachable: false)

        expect(custom_badge_text).to eq(check.human(:link_not_found))
      end
    end
  end
end
