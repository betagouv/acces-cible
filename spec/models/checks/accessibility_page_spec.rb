require "rails_helper"

RSpec.describe Checks::AccessibilityPage do
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

  describe "#analyze!" do
    let(:page) do
      instance_double(Page,
        url: "#{root_url}/accessibility",
        title: "Accessibility Statement"
      )
    end

    before do
      allow(check).to receive(:find_page).and_return(page)
    end

    it "returns hash with url and title" do
      result = check.send(:analyze!)
      expect(result).to eq({
        url: page.url,
        title: page.title
      })
    end

    it "returns empty hash when page is not found" do
      allow(check).to receive(:find_page).and_return(nil)
      result = check.send(:analyze!)
      expect(result).to eq({})
    end
  end

  describe "#find_page" do
    let(:crawler) { instance_double(Crawler) }
    let(:link_queue) { [] }

    before do
      allow(Crawler).to receive(:new).and_return(crawler)
      allow(crawler).to receive(:find).and_yield(page, link_queue)
    end

    context "with declaration in title" do
      let(:page) do
        instance_double(Page,
          url: "#{root_url}/accessibility",
          title: "Déclaration d'accessibilité",
          headings: [],
          text: ""
        )
      end

      it "returns the page" do
        expect(check.send(:find_page)).to eq(page)
      end
    end

    context "with declaration in headings" do
      let(:page) do
        instance_double(Page,
          url: "#{root_url}/accessibility",
          title: "Accessibility",
          headings: ["Déclaration d'accessibilité RGAA"],
          text: ""
        )
      end

      it "returns the page" do
        expect(check.send(:find_page)).to eq(page)
      end
    end

    context "with article 47 in text" do
      let(:page) do
        instance_double(Page,
          url: "#{root_url}/legal",
          title: "Legal Notice",
          headings: [],
          text: "article 47 loi n°2005-102 du 11 février 2005"
        )
      end

      it "returns the page" do
        expect(check.send(:find_page)).to eq(page)
      end
    end

    context "when no matching page is found" do
      let(:page) do
        instance_double(Page,
          url: "#{root_url}/other",
          title: "Other Page",
          headings: [],
          text: ""
        )
      end

      it "returns nil" do
        allow(crawler).to receive(:find).and_return(nil)
        expect(check.send(:find_page)).to be_nil
      end
    end
  end

  describe "#likelihood_of" do
    let(:link) { double("Link") }

    before do
      allow(link).to receive(:text).and_return("Some text")
      allow(link).to receive(:href).and_return("#{root_url}/some-path")
    end

    it "returns -1 if neither text nor href mention accessibility" do
      expect(check.send(:likelihood_of, link)).to eq(-1)
    end

    it "returns 0 if declaration is in text" do
      allow(link).to receive(:text).and_return("Déclaration d'accessibilité")
      expect(check.send(:likelihood_of, link)).to eq 0
    end

    it "returns 0 if accessibility is in href" do
      allow(link).to receive(:href).and_return("#{root_url}/declaration-accessibilite")
      expect(check.send(:likelihood_of, link)).to eq 0
    end

    it "returns 1 if both text and href have matches" do
      allow(link).to receive(:href).and_return("#{root_url}/declaration-accessibilite")
      allow(link).to receive(:text).and_return("Accessibilité : partiellement conforme")
      expect(check.send(:likelihood_of, link)).to eq 1
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
end
