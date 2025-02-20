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
