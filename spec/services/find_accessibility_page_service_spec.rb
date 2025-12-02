require "rails_helper"

RSpec.describe FindAccessibilityPageService do
  subject(:service) { described_class.call(audit) }

  let(:root_url) { "https://example.com" }
  let(:audit) { build(:audit, url: root_url) }

  describe "#find_page" do
    let(:matching_page_url) { "https://example.com/accessibility" }
    let(:matching_page) { build(:page, url: matching_page_url, title: "Accessibility") }
    let(:non_matching_page) { build(:page, url: "https://example.com", links: [build(:link, href: matching_page_url)]) }
    let(:crawler) { instance_double(Crawler) }

    before do
      allow(Crawler).to receive(:new).and_return(crawler)
      allow(described_class).to receive(:required_headings_present?).with(non_matching_page).and_return(false)
      allow(described_class).to receive(:required_headings_present?).with(matching_page).and_return(true)
      allow(described_class).to receive(:prioritize)
    end

    describe "find_page" do
      subject(:found_page) { described_class.send(:find_page, url: root_url, starting_html: "") }

      it "finds a matching page through crawling links" do
        expect(crawler).to receive(:find)
                             .and_yield(non_matching_page, LinkList.new(non_matching_page.url))
                             .and_yield(matching_page, LinkList.new(matching_page_url))
                             .and_return(matching_page)

        expect(found_page).to eq matching_page
      end

      it "continues crawling when page has insufficient headings" do
        page_with_insufficient_headings = build(:page, url: "https://example.com/partial", body: "Some content")

        allow(described_class).to receive(:required_headings_present?).with(page_with_insufficient_headings).and_return(false)

        expect(crawler).to receive(:find)
                             .and_yield(page_with_insufficient_headings, LinkList.new("https://example.com/other"))
                             .and_yield(matching_page, LinkList.new(matching_page_url))
                             .and_return(matching_page)

        expect(found_page).to eq matching_page
      end
    end
  end

  describe "#required_headings_present?" do
    subject(:headings_check) { described_class.send(:required_headings_present?, page) }

    let(:page) { build(:page, headings:, body: "") }
    let(:expected_headings) { Checks::AccessibilityPageHeading.expected_headings }
    let(:unrelated_headings) { ["Contact", "Accueil", "Actualités"] }

    [0, 2, 3, 6].each do |i|
      context "when #{i} required headings are present" do
        let(:headings) { unrelated_headings + expected_headings.first(i) }

        it { should eq(i >= described_class::REQUIRED_DECLARATION_HEADINGS) }
      end
    end
  end

  describe "#prioritize" do
    let(:short_rgaa_link) { build(:link, text: "RGAA", href: "/rgaa") }
    let(:long_declaration_link) { build(:link, text: "Page", href: "/declaration-accessibilite") }
    let(:declaration_daccessibilite_link) { build(:link, text: "Page", href: "/declaration-daccessibilite") }
    let(:declaration_text_link) { build(:link, text: "Déclaration d'accessibilité", href: "/other") }
    let(:accessibility_mention_link) { build(:link, text: "Accessibilité : totalement conforme", href: "/handicap") }
    let(:unrelated_link) { build(:link, text: "Contact", href: "/contact") }
    let(:queue) { LinkList.new(long_declaration_link, declaration_daccessibilite_link, declaration_text_link, accessibility_mention_link, short_rgaa_link, unrelated_link) }

    it "keeps links matching DECLARATION pattern in text"  do
      queue = LinkList.new(declaration_text_link, unrelated_link)

      described_class.send(:prioritize, queue)

      expect(queue.to_a).to contain_exactly("/other")
    end

    it "keeps links matching DECLARATION_URL pattern in href" do
      queue = LinkList.new(long_declaration_link, short_rgaa_link, unrelated_link)

      described_class.send(:prioritize, queue)

      expect(queue.to_a).to contain_exactly("/declaration-accessibilite", "/rgaa")
    end

    it "keeps links matching MENTION_REGEX pattern in text" do
      queue = LinkList.new(accessibility_mention_link, unrelated_link)

      described_class.send(:prioritize, queue)

      expect(queue.to_a).to contain_exactly("/handicap")
    end
  end
end
