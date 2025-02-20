require "rails_helper"

RSpec.describe Analyzers::AccessibilityPage do
  let(:analyzer) { described_class.send(:new, page:) }
  let(:page) do
    build(:page,
      url: "https://example.com/accessibilite",
      title: "Déclaration d'accessibilité RGAA",
      headings: ["Déclaration d'accessibilité RGAA"],
      body: <<~HTML
        <p>Audit réalisé le 15 mars 2024 par la Société ABC, qui révèle que le site est à 75% conforme au RGAA version 4.1.</p>
        <p>Article 47 de la loi n°2005-102 du 11 février 2005 etc…</p>
      HTML
    )
  end

  describe ".analyze" do
    it "returns complete accessibility information" do
      expect(analyzer.data).to include(
        url: page.url,
        title: page.title,
        audit_date: Date.new(2024, 3, 15),
        compliance_rate: 75,
        standard: "RGAA version 4.1",
        auditor: "ABC"
      )
    end

    context "when accessibility page is not found" do
      let(:page) { nil }

      it "returns an empty hash" do
        expect(analyzer.data).to eq({})
      end
    end
  end

  describe "#likelihood_of" do
    let(:basic_link) { build(:link, text: "Accessibilité", href: "/accessibilite") }
    let(:declaration_link) { build(:link, text: "Déclaration d'accessibilité", href: "/declaration-accessibilite") }
    let(:unrelated_link) { build(:link, text: "Contact", href: "/contact") }

    it "returns nil for non-Link objects" do
      expect(analyzer.likelihood_of("not a link")).to eq(nil)
    end

    it "returns  1 for links not matching any criteria" do
      expect(analyzer.likelihood_of(unrelated_link)).to eq(1)
    end

    it "returns  0 for links matching only one criteria" do
      expect(analyzer.likelihood_of(basic_link)).to eq(0)
    end

    it "returns -1 for links matching two criteria or more" do
      expect(analyzer.likelihood_of(declaration_link)).to eq(-1)
    end
  end

  describe "#sort_queue_by_likelihood(queue)" do
    let(:basic_link) { build(:link, text: "Accessibilité", href: "/accessibilite") }
    let(:declaration_link) { build(:link, text: "Déclaration d'accessibilité", href: "/declaration-accessibilite") }
    let(:unrelated_link) { build(:link, text: "Contact", href: "/contact") }
    let(:queue) { LinkList.new(basic_link, declaration_link, unrelated_link) }

    it "sorts the queue, with the likeliest links first" do
      expect(queue.to_a).to eq([basic_link, declaration_link, unrelated_link])
      analyzer.send(:sort_queue_by_likelihood, queue)
      expect(queue.to_a).to eq([declaration_link, basic_link, unrelated_link])
    end
  end

  describe "#find_page" do
    let(:non_matching_page) { build(:page, url: "https://example.com", links: [build(:link, href: matching_page_url)]) }
    let(:matching_page) { build(:page, url: matching_page_url, title: "Accessibility") }
    let(:matching_page_url) { "https://example.com/accessibility" }
    let(:analyzer) { described_class.send(:new, page: non_matching_page) }
    let(:crawler) { instance_double(Crawler) }

    before do
      allow(analyzer).to receive(:crawler).and_return(crawler)
      allow(analyzer).to receive(:accessibility_page?).with(non_matching_page).and_return(false)
      allow(analyzer).to receive(:accessibility_page?).with(matching_page).and_return(true)
      allow(analyzer).to receive(:sort_queue_by_likelihood)
    end

    it "finds a matching page through crawling links" do
      expect(crawler).to receive(:find)
        .and_yield(non_matching_page, LinkList.new(non_matching_page.url))
        .and_yield(matching_page, LinkList.new(matching_page_url))

      expect(analyzer.send(:find_page)).to eq(matching_page)
    end
  end

  describe "#accessibility_page?" do
    it "returns true when declaration is in title" do
      page = build(:page, title: "Déclaration d'accessibilité")
      expect(analyzer.send(:accessibility_page?, page)).to be true
    end

    it "returns true when declaration is in headings" do
      page = build(:page,
        title: "Other Page",
        headings: ["Déclaration d'accessibilité RGAA"]
      )
      expect(analyzer.send(:accessibility_page?, page)).to be true
    end

    it "returns true when article text is present" do
      page = build(:page,
        title: "Other Page",
        body: "article 47 loi n°2005-102 du 11 février 2005"
      )
      expect(analyzer.send(:accessibility_page?, page)).to be true
    end

    it "returns false for unrelated pages" do
      page = build(:page,
        title: "Contact",
        body: "Contactez-nous"
      )
      expect(analyzer.send(:accessibility_page?, page)).to be false
    end
  end

  describe "#audit_date" do
    {
      "réalisé le 15 mars 2024" => Date.new(2024, 3, 15),
      "réalisée 1er février 2024" => Date.new(2024, 2, 1),
      "en mars 2024" => Date.new(2024, 3, 1),
      "du 15 février 2024" => Date.new(2024, 2, 15),
      "du 35 mai 2024" => nil
    }.each do |text, expected_date|
      it "handles '#{text}'" do
        allow(analyzer).to receive(:page).and_return(build(:page, body: text))
        expect(analyzer.audit_date).to eq(expected_date)
      end
    end
  end

  describe "#compliance_rate" do
    {
      "avec un taux de conformité 81,25%" => 81.25,
      "taux de conformité de 75%" => 75,
      "conforme à 80,5%" => 80.5,
      "révèle que 90.5%" => 90.5,
      "taux de conformité globale est de 95 pour cent" => 95
    }.each do |text, expected_rate|
      it "extracts '#{expected_rate}%' from '#{text}'" do
        allow(analyzer).to receive(:page).and_return(build(:page, body: text))
        expect(analyzer.compliance_rate).to eq(expected_rate)
      end
    end
  end

  describe "#standard" do
    {
      "conforme au RGAA version 4.1." => "RGAA version 4.1",
      "les administrations, RGAA version 4.1.2, " => "RGAA version 4.1.2",
      "RGAA v4.1.1" => "RGAA v4.1.1",
      "au RGAA" => "RGAA",
      "des critères WCAG" => "WCAG"
    }.each do |text, expected_standard|
      it "extracts '#{expected_standard}' from '#{text}'" do
        allow(analyzer).to receive(:page).and_return(build(:page, body: text))
        expect(analyzer.standard).to eq(expected_standard)
      end
    end
  end

  describe "#auditor" do
    {
      "par la société ABC," => "ABC",
      "par XYZ (cabinet d'audit assermenté)," => "XYZ (cabinet d'audit assermenté)",
      "par Test Corp révèle" => "Test Corp",
      "par AXS Consulting sur un échantillon…" => "AXS Consulting"
    }.each do |text, expected_auditor|
      it "extracts '#{expected_auditor}' from '#{text}'" do
        allow(analyzer).to receive(:page).and_return(build(:page, body: text))
        expect(analyzer.auditor).to eq(expected_auditor)
      end
    end
  end
end
