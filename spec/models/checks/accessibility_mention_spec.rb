require "rails_helper"

RSpec.describe Checks::AccessibilityMention do
  let(:check) { described_class.new }

  describe "#find_mention" do
    subject(:mention) { check.send(:find_mention) }

    before do
      allow(check).to receive(:root_page_text).and_return(text)
    end

    {
      # Basic formats
      "accessibilité : non conforme" => "non",
      "accessibilité : partiellement conforme" => "partiellement",
      "accessibilité : totalement conforme" => "totalement",
      "accessibilité:totalement conforme" => "totalement",
      "accessibilité (non conforme)" => "non",
      "accessibilité (partiellement conforme)" => "partiellement",

      # With "site"
      "accessibilité du site : non conforme" => "non",

      # No punctuation
      "accessibilité partiellement conforme" => "partiellement",

      # Case variations
      "ACCESSIBILITE : NON CONFORME" => "non",
      "Accessibilité : Partiellement Conforme" => "partiellement",

      # Extra spacing
      "accessibilité  :  totalement conforme" => "totalement",
      "accessibilité ( partiellement conforme )" => "partiellement",

      # Invalid formats
      "" => nil,
      "Accessibillité (non conforme)" => nil,
      "accessibilité de n'importe quoi : totalement conforme" => nil,
      "accessibilité : totalement non conforme" => nil,
      "accessibilité : pas vraiment conforme" => nil,
      "accessibilité conforme" => nil
    }.each do |text, expectation|
      context "when page contains '#{text}'" do
        let(:text) { text }

        it "returns '#{expectation}'" do
          expect(mention).to eq(expectation)
        end
      end
    end
  end

  describe "#custom_badge_status" do
    subject(:badge_status) { check.send(:custom_badge_status) }

    {
      nil => :error,
      non: :warning,
      partiellement: :new,
      totalement: :success
    }.each do |mention, status|
      context "when mention is #{mention || 'nil'}" do
        it "returns :#{status}" do
          check.mention = mention
          expect(badge_status).to eq(status)
        end
      end
    end
  end
end
