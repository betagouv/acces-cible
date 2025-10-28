require "rails_helper"

RSpec.describe Checks::FindAccessibilityPage do
  let(:root_url) { "https://example.com" }
  let(:audit) { build(:audit) }
  let(:check) { described_class.new(audit:) }

  describe "#found?" do
    it "returns true when url is present" do
      check.url = "#{root_url}/accessibility"
      expect(check.send(:found?)).to be true
    end

    it "returns false when url is blank" do
      check.url = nil
      expect(check.send(:found?)).to be false
    end
  end

  describe "#custom_badge_text" do
    it "returns :link_to_page when url is present" do
      expect(check).to receive(:human).with(:link_to_page)
      check.url = "#{root_url}/accessibility"
      check.send(:custom_badge_text)
    end

    it "returns :not_found when url is blank" do
      check.url = nil
      expect(check.send(:custom_badge_text)).to eq(check.human(:not_found))
    end
  end

  describe "#custom_badge_status" do
    it "returns :success when url is present" do
      check.url = "#{root_url}/accessibility"
      expect(check.send(:custom_badge_status)).to eq(:success)
    end

    it "returns :error when url is blank" do
      check.url = nil
      expect(check.send(:custom_badge_status)).to eq(:error)
    end
  end

  describe "#find_page" do
    let(:non_matching_page) { build(:page, url: "https://example.com", links: [build(:link, href: matching_page_url)]) }
    let(:matching_page) { build(:page, url: matching_page_url, title: "Accessibility") }
    let(:matching_page_url) { "https://example.com/accessibility" }
    let(:crawler) { instance_double(Crawler) }

    before do
      allow(check).to receive(:crawler).and_return(crawler)
      allow(check).to receive(:required_headings_present?).with(non_matching_page).and_return(false)
      allow(check).to receive(:required_headings_present?).with(matching_page).and_return(true)
      allow(check).to receive(:prioritize)
    end

    it "finds a matching page through crawling links" do
      expect(crawler).to receive(:find)
        .and_yield(non_matching_page, LinkList.new(non_matching_page.url))
        .and_yield(matching_page, LinkList.new(matching_page_url))
        .and_return(matching_page)

      expect(check.send(:find_page)).to be(matching_page)
    end

    it "continues crawling when page has insufficient headings" do
      page_with_insufficient_headings = build(:page, url: "https://example.com/partial", body: "Some content")

      allow(check).to receive(:required_headings_present?).with(page_with_insufficient_headings).and_return(false)

      expect(crawler).to receive(:find)
        .and_yield(page_with_insufficient_headings, LinkList.new("https://example.com/other"))
        .and_yield(matching_page, LinkList.new(matching_page_url))
        .and_return(matching_page)

      expect(check.send(:find_page)).to be(matching_page)
    end
  end

  describe "#required_headings_present?" do
    subject(:headings_check) { check.send(:required_headings_present?, page) }

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

    it "filters queue and sorts links by href length" do
      check.send(:prioritize, queue)

      expect(queue.to_a).to eq ["/rgaa", "/other", "/handicap", "/declaration-accessibilite", "/declaration-daccessibilite"]
      expect(queue.to_a).not_to include("/contact")
    end

    it "keeps links matching DECLARATION pattern in text" do
      queue = LinkList.new(declaration_text_link, unrelated_link)
      check.send(:prioritize, queue)

      expect(queue.to_a).to contain_exactly("/other")
    end

    it "keeps links matching DECLARATION_URL pattern in href" do
      queue = LinkList.new(long_declaration_link, short_rgaa_link, unrelated_link)
      check.send(:prioritize, queue)

      expect(queue.to_a).to contain_exactly("/declaration-accessibilite", "/rgaa")
    end

    it "keeps links matching MENTION_REGEX pattern in text" do
      queue = LinkList.new(accessibility_mention_link, unrelated_link)
      check.send(:prioritize, queue)

      expect(queue.to_a).to contain_exactly("/handicap")
    end
  end
end
