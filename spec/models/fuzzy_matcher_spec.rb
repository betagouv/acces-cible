require "rails_helper"

RSpec.describe FuzzyMatcher do
  subject(:matcher) { described_class.new(target_text) }

  let(:target_text) { "Schéma pluriannuel" }

  describe "#match?" do
    it "matches identical text" do
      expect(matcher.match?(target_text)).to be true
    end

    it "matches text with different case" do
      expect(matcher.match?(target_text.upcase)).to be true
    end

    it "matches text with minor typos" do
      expect(matcher.match?("Schéma pluri-anuel")).to be true
    end

    it "does not match significantly different text" do
      expect(matcher.match?("Completely different")).to be false
    end

    it "does not match empty string" do
      expect(matcher.match?("")).to be false
    end

    it "does not match nil" do
      expect(matcher.match?(nil)).to be false
    end
  end
end
