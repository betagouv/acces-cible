require "rails_helper"

RSpec.describe Checks::AnalyzePlan do
  let(:audit) { build(:audit) }
  let(:check) { described_class.new(audit:) }

  describe ".analyze!" do
    subject(:analyze) { check.send(:analyze!) }

    context "when there is no accessibility page" do
      it "returns nil" do
        allow(audit).to receive(:page).with(:accessibility).and_return(nil)

        expect(analyze).to be_nil
      end
    end

    context "when find_link and find_page_heading both return nil" do
      it "returns nil" do
        page = build(:page, links: ["invalid link"], headings: [])
        allow(audit).to receive(:page).with(:accessibility).and_return(page)

        expect(analyze).to be_nil
      end
    end

    context "when a link is found" do
      let(:year) { Time.current.year }

      it "returns a hash containing link_url, link_text, years, reachable, and valid_year" do
        link = Link.new(href: "https://www.example.com/plan_annuel.pdf", text: "Plan annuel d'accessibilité #{year}")
        page = build(:page, links: [link], headings: [])
        allow(check).to receive(:page).and_return(page)
        allow(Browser).to receive(:exists?).with(link.href).and_return(true)

        expect(analyze).to include(
          link_url: link.href,
          link_text: link.text,
          years: [year],
          reachable: true,
          valid_year: true,
          page_heading: nil
        )
      end
    end

    context "when find_link returns nil but find_page_heading matches" do
      let(:year) { Time.current.year }

      it "returns a hash with page_heading and extracted years" do
        page = build(:page, links: [], headings: ["Plan annuel d'accessibilité #{year}"])
        allow(audit).to receive(:page).with(:accessibility).and_return(page)

        expect(analyze).to include(
          link_url: nil,
          link_text: nil,
          years: [year],
          reachable: nil,
          valid_year: true,
          page_heading: "Plan annuel d'accessibilité #{year}"
        )
      end
    end
  end

  describe "#find_link" do
    subject(:find_link) { check.find_link }

    let(:page) { build(:page, links:) }

    before { allow(audit).to receive(:page).with(:accessibility).and_return(page) }

    context "when link text matches pattern" do
      [
        "Plan annuel d'accessibilité",
        "Plan annuel d'accessibilité numérique",
        "PLAN ANNUEL D'ACCESSIBILITE NUMERIQUE",
        "Plan annuel d'accessibilité 2024",
        "Plan annuel d'accessibilité numérique 2024-2025",
        "Plan annuel 2024",
        "PLAN ANNUEL 2024",
        "Plan d’action",
        "Plan d'actions",
        "PLAN D'ACTION 2025",
        "PLAN D'ACTIONS 2025",
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
        "Schéma d'accessibilité",
        "Déclaration d'accessibilité",
        "Accessibilité",
        "Documentation",
        "Plan directeur",
        "Plan annuel de formation",
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
          "Plan annuel d'accessibilité 2020",
          "Plan annuel d'accessibilité 2023-2025",
          "Plan annuel d'accessibilité 2021",
        ]
      end

      it "returns the link with the highest years" do
        expect(find_link.text).to eq("Plan annuel d'accessibilité 2023-2025")
      end
    end
  end

  describe "#extract_years" do
    {
      "Plan annuel d'accessibilité" => [],
      "Plan annuel d'accessibilité 2024" => [2024],
      "PLAN ANNUEL D'ACCESSIBILITE NUMERIQUE 2023-2025" => [2023, 2025],
      "PLAN ANNUEL D'ACCESSIBILITE NUMERIQUE 2025-2023" => [2023, 2025],
    }.each do |text, expected_result|
      it "extracts #{expected_result.inspect} from '#{text}'" do
        expect(check.send(:extract_years, text)).to eq(expected_result)
      end
    end
  end

  describe "#validate_year" do
    current_year = Date.current.year
    {
      current_year + 2 => false,
      current_year + 1 => true,
      current_year     => true,
      current_year - 1 => true,
      current_year - 2 => false
    }.each do |year, expected_result|
      it "returns #{expected_result} for #{year}" do
        expect(check.send(:validate_year, year)).to eq(expected_result)
      end
    end
  end

  describe "#custom_badge_status" do
    subject(:custom_badge_status) { check.custom_badge_status }

    context "when all passed" do
      it "returns :success" do
        allow(check).to receive_messages(link_url: "url", valid_year: true, reachable: true, page_heading: nil)

        expect(custom_badge_status).to eq(:success)
      end
    end

    context "when link is valid but year is invalid" do
      it "returns :warning" do
        allow(check).to receive_messages(link_url: "url", valid_year: false, reachable: true, page_heading: nil)

        expect(custom_badge_status).to eq(:warning)
      end
    end

    context "when plan is in page heading" do
      it "returns :warning" do
        allow(check).to receive_messages(link_url: nil, valid_year: false, reachable: false, page_heading: "Plan annuel")

        expect(custom_badge_status).to eq(:warning)
      end
    end

    context "when link_url is nil found and page_heading too" do
      it "returns :error" do
        allow(check).to receive_messages(link_url: nil, valid_year: false, reachable: false, page_heading: nil)

        expect(custom_badge_status).to eq(:error)
      end
    end
  end

  describe "#custom_badge_text" do
    subject(:custom_badge_text) { check.custom_badge_text }

    context "when all passed" do
      it "returns human(:all_passed)" do
        allow(check).to receive_messages(link_url: "url", valid_year: true, reachable: true, page_heading: nil)

        expect(custom_badge_text).to eq(check.human(:all_passed))
      end
    end

    context "when link is valid but year is invalid" do
      it "returns human(:invalid_year)" do
        allow(check).to receive_messages(link_url: "url", valid_year: false, reachable: true, page_heading: nil)

        expect(custom_badge_text).to eq(check.human(:invalid_year))
      end
    end

    context "when plan is in page heading" do
      it "returns human(:plan_in_page_heading)" do
        allow(check).to receive_messages(link_url: nil, valid_year: false, reachable: false, page_heading: "Plan annuel")

        expect(custom_badge_text).to eq(check.human(:plan_in_page_heading))
      end
    end

    context "when link_url is nil found and page_heading too" do
      it "returns human(:link_not_found)" do
        allow(check).to receive_messages(link_url: nil, valid_year: false, reachable: false, page_heading: nil)

        expect(custom_badge_text).to eq(check.human(:link_not_found))
      end
    end
  end
end
