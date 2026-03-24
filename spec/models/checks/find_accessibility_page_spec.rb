require "rails_helper"

RSpec.describe Checks::FindAccessibilityPage do
  let(:root_url) { "https://example.com" }
  let(:audit) { build(:audit, accessibility_page_url: "#{root_url}/accessibility") }
  let(:check) { described_class.new(audit:) }

  describe "#analyze!" do
    subject(:analyze) { check.send(:analyze!) }

    context "when no accessibility page was found" do
      before do
        audit.update!(accessibility_page_url: nil)
      end

      it { is_expected.to be_nil }
    end

    context "when the accessibility page was found and its URL stored" do
      it "returns a hash with the URL and internal = true" do
        expect(analyze).to eq(url: "#{root_url}/accessibility", internal: true)
      end
    end

    context "when the accessibility page is external" do
      before do
        audit.update!(
            home_page_url: "https://example.com",
            accessibility_page_url: "https://external.example.org/accessibilite"
          )
      end

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
    it "returns :success when url is present" do
      check.url = "#{root_url}/accessibility"
      check.internal = true
      expect(check.send(:custom_badge_status)).to eq(:success)
    end

    it "returns :warning when url is present and external" do
      check.url = "#{root_url}/accessibility"
      check.internal = false
      expect(check.send(:custom_badge_status)).to eq(:warning)
    end

    it "returns :error when url is blank even if internal is nil" do
      check.url = nil
      check.internal = nil
      expect(check.send(:custom_badge_status)).to eq(:error)
    end
  end
end
