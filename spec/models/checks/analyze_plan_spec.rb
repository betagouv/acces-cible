require "rails_helper"

RSpec.describe Checks::AnalyzePlan do
  let(:audit) { build(:audit) }
  let(:check) { described_class.new(audit:) }
  let(:current_year) { Date.current.year }

  describe ".analyze!" do
    subject(:analyze) { check.send(:analyze!) }

    context "when there is no accessibility page" do
      it "returns nil" do
        allow(audit).to receive(:page).with(:accessibility).and_return(nil)

        expect(analyze).to be_nil
      end
    end

    context "when find_link and find_text_in_main both return nil" do
      it "returns nil" do
        page = build(:page, body: "<p>Text that doesn't match</p>")
        allow(audit).to receive(:page).with(:accessibility).and_return(page)

        expect(analyze).to be_nil
      end
    end

    context "when a link is found" do
      let(:root) { "https://www.example.com" }

      it "returns a hash containing link_url, link_text, years, reachable, valid_year, and link_misplaced" do
        link = Link.new(href: "#{root}/plan_annuel.pdf", text: "Plan annuel d'accessibilité #{current_year}")
        body = <<~HTML
          <h1>Déclaration d'accessibilité</h1>
          <a href="#{link.href}">#{link.text}</a>
          <h2>État de conformité</h2>
        HTML
        page = build(:page, body:)
        allow(check).to receive(:page).and_return(page)
        allow(Browser).to receive(:reachable?).with(link.href).and_return(true)

        expect(analyze).to include(
                             link_url: link.href,
                             link_text: link.text,
                             link_misplaced: false,
                             years: [current_year],
                             reachable: true,
                             valid_years: true,
                             text: nil
                           )
      end

      context "and years are in link.href instead of link.text" do
        it "extracts years from href" do
          years = [current_year]
          link = Link.new(href: "#{root}/plan-annuel-#{years.join("-")}.pdf", text: "Plan annuel d'accessibilité")
          page = build(:page, links: [link])
          allow(check).to receive_messages(page:)
          allow(Browser).to receive(:reachable?).with(link.href).and_return(true)

          expect(analyze).to include(
                               link_url: link.href,
                               link_text: link.text,
                               years: [current_year],
                               reachable: true,
                               valid_years: true
                             )
        end
      end

      context "and years are in both link.text and link.href" do
        it "prefers years from link.text" do
          link = Link.new(href: "#{root}/plan-#{current_year + 10}.pdf", text: "Plan annuel d'accessibilité #{current_year}")
          page = build(:page, links: [link])
          allow(check).to receive_messages(page:)
          allow(Browser).to receive(:reachable?).with(link.href).and_return(true)

          expect(analyze).to include(years: [current_year])
        end
      end
    end

    context "when find_link returns nil but find_text_in_main matches" do
      it "returns a hash with text and extracted years" do
        page = build(:page, body: "<p>Plan annuel d'accessibilité #{current_year}</p>")
        allow(audit).to receive(:page).with(:accessibility).and_return(page)

        expect(analyze).to include(
                             link_url: nil,
                             link_text: nil,
                             link_misplaced: nil,
                             years: [current_year],
                             reachable: nil,
                             valid_years: true,
                             text: "Plan annuel d'accessibilité #{current_year}"
                           )
      end
    end
  end

  describe "#find_link" do
    subject(:find_link) { check.find_link }

    let(:links_html) { links.map { |link| %(<a href="#{link}">#{link}</a>) }.join("\n") }
    let(:page_html) do
      <<~HTML
        <!DOCTYPE html>
        <html>
        <body>
          <h1>Déclaration d'accessibilité</h1>
          #{links_html}
          <h1>État de conformité</h1>
        </body>
        </html>
      HTML
    end
    let(:page) { build(:page, html: page_html) }

    before { allow(audit).to receive(:page).with(:accessibility).and_return(page) }

    context "when link text matches pattern" do
      current_year = Date.current.year
      [
        "Plan annuel d'accessibilité",
        "Plan annuel d'accessibilité numérique",
        "PLAN ANNUEL D'ACCESSIBILITE NUMERIQUE",
        "Plan annuel d'accessibilité #{current_year - 1}",
        "Plan annuel d'accessibilité numérique #{current_year - 1}-#{current_year}",
        "Plan annuel de mise en accessibilité #{current_year}",
        "Plan annuel #{current_year - 1}",
        "PLAN ANNUEL #{current_year - 1}",
        "Plan d’action",
        "Plan d'actions",
        "PLAN D'ACTION #{current_year}",
        "PLAN D'ACTIONS #{current_year}",
        "Plan #{current_year} d'action",
        "Plan #{current_year} d'actions",
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
          "Plan annuel d'accessibilité #{current_year - 10}",
          "Plan annuel d'accessibilité #{current_year - 1}-#{current_year + 1}",
          "Plan annuel d'accessibilité #{current_year - 3}-#{current_year + 3}",
        ]
      end

      it "returns the link with the valid years" do
        expect(find_link.text).to eq("Plan annuel d'accessibilité #{current_year - 1}-#{current_year + 1}")
      end
    end
  end

  describe "#link_between_headings?" do
    subject(:link_between_headings) { check.link_between_headings? }

    context "when link is between the correct headings" do
      it "returns the link" do
        link_text = "Plan annuel d'accessibilité #{current_year - 1}"
        page_html = <<~HTML
          <!DOCTYPE html>
          <html>
          <body>
            <h1>Déclaration d'accessibilité</h1>
            <a href="plan.pdf">#{link_text}</a>
            <h2>État de conformité</h2>
          </body>
          </html>
        HTML
        page = build(:page, html: page_html)
        allow(audit).to receive(:page).with(:accessibility).and_return(page)

        expect(link_between_headings.text).to eq(link_text)
      end
    end

    context "when link is not between the correct headings" do
      it "returns nil" do
        page_html = <<~HTML
          <!DOCTYPE html>
          <html>
          <body>
            <h1>Déclaration d'accessibilité</h1>
            <h2>État de conformité</h2>
            <a href="plan.pdf">Plan annuel d'accessibilité #{current_year - 1}</a>
          </body>
          </html>
        HTML
        page = build(:page, html: page_html)
        allow(audit).to receive(:page).with(:accessibility).and_return(page)

        expect(link_between_headings).to be_nil
      end
    end

    context "when there is no page" do
      it "returns nil" do
        allow(audit).to receive(:page).with(:accessibility).and_return(nil)

        expect(link_between_headings).to be_nil
      end
    end

    context "when multiple links match between headings" do
      it "returns the link with the highest years" do
        page_html = <<~HTML
          <!DOCTYPE html>
          <html>
          <body>
            <h1>Déclaration d'accessibilité</h1>
            <a href="plan#{current_year - 3}.pdf">Plan annuel d'accessibilité #{current_year - 3}</a>
            <a href="plan#{current_year}.pdf">Plan annuel d'accessibilité #{current_year}</a>
            <a href="plan#{current_year + 3}.pdf">Plan annuel d'accessibilité #{current_year + 3}</a>
            <h2>État de conformité</h2>
          </body>
          </html>
        HTML
        page = build(:page, html: page_html)
        allow(audit).to receive(:page).with(:accessibility).and_return(page)

        expect(link_between_headings.text).to eq("Plan annuel d'accessibilité #{current_year + 3}")
      end
    end
  end

  describe "#find_text_in_main" do
    subject { check.find_text_in_main }

    let(:page) { build(:page, body:) }

    before { allow(check).to receive(:page).and_return(page) }

    context "when main text does not match pattern" do
      let(:body) { "<main><p>Plan directeur</p></main>" }

      it { should be_nil }
    end

    context "when main text matches pattern" do
      let(:body) { "Plan annuel d'accessibilité #{current_year - 1}" }

      it { should eq(body) }
    end

    context "when multiple matches exist in main text" do
      let(:body) do
        "<p>Plan annuel d'accessibilité #{current_year - 10}</p>
        <p>Plan annuel d'accessibilité #{current_year - 1}-#{current_year + 1}</p>
        <p>Plan annuel d'accessibilité  #{current_year - 3}-#{current_year + 3}</p>"
      end

      it { should eq("Plan annuel d'accessibilité #{current_year - 1}-#{current_year + 1}") }
    end
  end

  describe "#extract_valid_years" do
    current_year = Date.current.year
    {
      "Plan annuel d'accessibilité" => [],
      "Plan annuel d'accessibilité #{current_year - 10}" => [current_year - 10],
      "Plan annuel d'accessibilité #{current_year - 1}" => [current_year - 1],
      "uploads/#{current_year}/plan-annuel-#{current_year}02.pdf" => [current_year],
      "PLAN ANNUEL D'ACCESSIBILITE NUMERIQUE #{current_year - 1}-#{current_year}" => [current_year - 1, current_year],
      "PLAN ANNUEL D'ACCESSIBILITE NUMERIQUE #{current_year}-#{current_year - 1}" => [current_year - 1, current_year],
    }.each do |text, expected_result|
      it "extracts #{expected_result.inspect} from '#{text}'" do
        expect(check.send(:extract_valid_years, text)).to eq(expected_result)
      end
    end
  end

  describe "#within_three_years?" do
    current_year = Date.current.year
    {
      [current_year + 2] => false,
      [current_year + 1] => true,
      [current_year] => true,
      [current_year - 1] => true,
      [current_year - 2] => false
    }.each do |year, expected_result|
      it "returns #{expected_result} for #{year}" do
        expect(check.send(:within_three_years?, year)).to eq(expected_result)
      end
    end
  end

  describe "#custom_badge_status" do
    subject(:custom_badge_status) { check.custom_badge_status }

    context "when all passed" do
      it "returns :success" do
        allow(check).to receive_messages(link_url: "url", valid_years: true, reachable: true, text: nil)

        expect(custom_badge_status).to eq(:success)
      end
    end

    context "when link is valid but year is invalid" do
      it "returns :warning" do
        allow(check).to receive_messages(link_url: "url", valid_years: false, reachable: true, text: nil)

        expect(custom_badge_status).to eq(:warning)
      end
    end

    context "when plan is in main text" do
      it "returns :warning" do
        allow(check).to receive_messages(link_url: nil, valid_years: false, reachable: false, text: "Plan annuel")

        expect(custom_badge_status).to eq(:warning)
      end
    end

    context "when link_url is nil found and text too" do
      it "returns :error" do
        allow(check).to receive_messages(link_url: nil, valid_years: false, reachable: false, text: nil)

        expect(custom_badge_status).to eq(:error)
      end
    end
  end

  describe "#custom_badge_text" do
    subject(:custom_badge_text) { check.custom_badge_text }

    context "when all passed" do
      it "returns all passed" do
        allow(check).to receive_messages(link_url: "url", valid_years: true, reachable: true, text: nil)

        expect(custom_badge_text).to eq("Lien trouvé et valide")
      end
    end

    context "when link is valid but year is not within 3 years" do
      it "returns invalid years" do
        allow(check).to receive_messages(link_url: "url", valid_years: false, reachable: true, text: nil, years: [2020])

        expect(custom_badge_text).to eq("Année(s) invalide(s)")
      end
    end

    context "when link is valid but year is invalid" do
      it "returns invalid years" do
        allow(check).to receive_messages(link_url: "url", valid_years: false, reachable: true, text: nil, years: [])

        expect(custom_badge_text).to eq("Année(s) valides non trouvée(s)")
      end
    end

    context "when link_url is nil found and text too" do
      it "returns not found" do
        allow(check).to receive_messages(link_url: nil, valid_years: false, reachable: false, text: nil)

        expect(custom_badge_text).to eq("Lien non trouvé")
      end
    end
  end
end
