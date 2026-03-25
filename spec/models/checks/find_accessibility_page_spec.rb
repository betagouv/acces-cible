require "rails_helper"

RSpec.describe Checks::FindAccessibilityPage do
  let(:root_url) { "https://example.com" }
  let(:home_page_url) { root_url }
  let(:accessibility_page_url) { "#{root_url}/accessibility" }
  let(:audit) { build(:audit, home_page_url:, accessibility_page_url:) }
  let(:check) { described_class.new(audit:) }

  describe "#analyze!" do
    subject(:analyze) { check.send(:analyze!) }

    context "when no accessibility page was found" do
      let(:accessibility_page_url) { nil }

      it { is_expected.to be_nil }
    end

    context "when the accessibility page was found and its URL stored" do
      it "returns a hash with the URL and internal = true" do
        expect(analyze).to eq(url: "#{root_url}/accessibility", internal: true)
      end
    end

    context "when the accessibility page is external" do
      let(:accessibility_page_url) { "https://external.example.org/accessibilite" }

      it "returns the URL and internal = false" do
        expect(analyze).to eq(
          url: "https://external.example.org/accessibilite",
          internal: false
        )
      end
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
    it "returns :success when url is present and internal" do
      check.url = "#{root_url}/accessibility"
      check.internal = true
      expect(check.send(:custom_badge_status)).to eq(:success)
    end

    it "returns :warning when url is present and external" do
      check.url = "#{root_url}/accessibility"
      check.internal = false
      expect(check.send(:custom_badge_status)).to eq(:warning)
    end

    it "returns :success when internal is nil to preserve legacy behavior" do
      check.url = "#{root_url}/accessibility"
      check.internal = nil
      expect(check.send(:custom_badge_status)).to eq(:success)
    end

    it "returns :error when url is blank even if internal is nil" do
      check.url = nil
      check.internal = nil
      expect(check.send(:custom_badge_status)).to eq(:error)
    end
  end
end
