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
    it "returns :link_to { name: site.name } when url is present" do
      expect(check).to receive(:human).with(:link_to, { name: nil })
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

  describe "#likelihood_of" do
    let(:basic_link) { build(:link, text: "Accessibilité", href: "/accessibilite") }
    let(:declaration_link) { build(:link, text: "Déclaration d'accessibilité", href: "/declaration-accessibilite") }
    let(:unrelated_link) { build(:link, text: "Contact", href: "/contact") }

    it "returns nil for non-Link objects" do
      expect(check.send(:likelihood_of, "not a link")).to be_nil
    end

    it "returns 1 for links not matching any criteria" do
      expect(check.send(:likelihood_of, unrelated_link)).to eq(1)
    end

    it "returns 0 for links matching only one criteria" do
      expect(check.send(:likelihood_of, basic_link)).to eq(0)
    end

    it "returns -1 for links matching two criteria or more" do
      expect(check.send(:likelihood_of, declaration_link)).to eq(-1)
    end
  end

  describe "#sort_queue_by_likelihood(queue)" do
    let(:basic_link) { build(:link, text: "Accessibilité", href: "/accessibilite") }
    let(:declaration_link) { build(:link, text: "Déclaration d'accessibilité", href: "/declaration-accessibilite") }
    let(:unrelated_link) { build(:link, text: "Contact", href: "/contact") }
    let(:queue) { LinkList.new(basic_link, declaration_link, unrelated_link) }

    it "sorts the queue, with the likeliest links first" do
      expect(queue.to_a).to eq([basic_link, declaration_link, unrelated_link])
      check.send(:sort_queue_by_likelihood, queue)
      expect(queue.to_a).to eq([declaration_link, basic_link, unrelated_link])
    end
  end

  describe "#find_page" do
    let(:non_matching_page) { build(:page, url: "https://example.com", links: [build(:link, href: matching_page_url)]) }
    let(:matching_page) { build(:page, url: matching_page_url, title: "Accessibility") }
    let(:matching_page_url) { "https://example.com/accessibility" }
    let(:crawler) { instance_double(Crawler) }

    before do
      allow(check).to receive(:crawler).and_return(crawler)
      allow(check).to receive(:accessibility_page?).with(non_matching_page).and_return(false)
      allow(check).to receive(:accessibility_page?).with(matching_page).and_return(true)
      allow(check).to receive(:sort_queue_by_likelihood)
    end

    it "finds a matching page through crawling links" do
      expect(crawler).to receive(:find)
        .and_yield(non_matching_page, LinkList.new(non_matching_page.url))
        .and_yield(matching_page, LinkList.new(matching_page_url))

      expect(check.send(:find_page)).to be(true)
    end
  end

  describe "#accessibility_page?" do
    {
      "Déclaration de conformité" => false,
      "DECLARATION D'ACCESSIBILITE" => true,
      "Déclaration d’accessibilité" => true,
      "Déclaration d’accessibilité du site internet" => true,
    }.each do |title, expectation|
      context "when page title is '#{title}'" do
        subject { check.send(:accessibility_page?, page) }

        let(:page) { build(:page, title:) }

        it { is_expected.to eq(expectation) }
      end
    end

    it "returns true when declaration is in headings" do
      page = build(:page,
        title: "Other Page",
        headings: ["Déclaration d'accessibilité RGAA"]
      )
      expect(check.send(:accessibility_page?, page)).to be true
    end

    it "returns true when article text is present" do
      page = build(:page,
        title: "Other Page",
        body: "article 47 loi n°2005-102 du 11 février 2005"
      )
      expect(check.send(:accessibility_page?, page)).to be true
    end

    it "returns false for unrelated pages" do
      page = build(:page,
        title: "Contact",
        body: "Contactez-nous"
      )
      expect(check.send(:accessibility_page?, page)).to be false
    end
  end
end
