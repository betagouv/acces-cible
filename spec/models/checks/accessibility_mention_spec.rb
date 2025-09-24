require "rails_helper"

RSpec.describe Checks::AccessibilityMention do
  let(:check) { described_class.new }

  describe "#find_mention" do
    subject(:mention) { check.send(:find_mention) }

    before do
      allow(check).to receive(:root_page_text).and_return(text)
    end

    {
      "" => nil,
      "ACCESSIBILITE : NON CONFORME" => "non",
      "Accessibilité : partiellement conforme" => "partiellement",
      "accessibilité : totalement conforme" => "totalement",
      "accessibilité (non conforme)" => "non",
      "accessibilité du site : totalement conforme" => nil,
      "accessibilité : totalement non conforme" => nil,
      "accessibilité : pas vraiment vraiment conforme" => nil,
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
