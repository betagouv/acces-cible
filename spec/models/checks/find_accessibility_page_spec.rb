require "rails_helper"

RSpec.describe Checks::FindAccessibilityPage do
  let(:root_url) { "https://example.com" }
  let(:audit) { build(:audit, accessibility_page_url: "#{root_url}/accessibility") }
  let(:check) { described_class.new(audit:) }

  describe "#analyze!" do
    subject(:analyze) { check.send(:analyze!) }

    it "returns a hash with :url and :title" do
      expect(analyze).to eq({ url: audit.accessibility_page_url })
    end
  end

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
      check.url = "#{root_url}/accessibility"
      expect(check.send(:custom_badge_text)).to eq("Déclaration d'accessibilité")
    end

    it "returns :not_found when url is blank" do
      check.url = nil
      expect(check.send(:custom_badge_text)).to eq("Non trouvée")
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
