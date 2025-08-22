require "rails_helper"

RSpec.describe Checks::LanguageIndication do
  let(:check) { described_class.new }

  describe "#find_language_indication" do
    subject(:indication) { check.send(:find_language_indication) }

    before do
      # rubocop:disable RSpec/MessageChain
      allow(check).to receive_message_chain("root_page.dom.root.attributes").and_return(attributes)
      # rubocop:enable RSpec/MessageChain
    end

    {
      "fr" => "fr",
      "fr-FR" => "fr-FR",
      "  fr-CA  " => "fr-CA",
      "" => "",
      "   " => "",
      nil => nil
    }.each do |value, expected_result|
      context "when lang attribute #{value.inspect}" do
        let(:attributes) { { "lang" => double(value:) } } # rubocop:disable RSpec/VerifiedDoubles

        it "returns #{expected_result.inspect}" do
          expect(indication).to eq(expected_result)
        end
      end
    end
  end

  describe "#custom_badge_status" do
    subject(:badge_status) { check.send(:custom_badge_status) }

    {
      nil => :error,
      "" => :error,
      "fr" => :success,
      "FR" => :success,
      "fr-FR" => :success,
      "FR-CA" => :success,
      "fr_FR" => :success,
      "en" => :warning,
      "es-ES" => :warning
    }.each do |indication, status|
      context "when indication is #{indication.inspect}" do
        it "returns :#{status}" do
          check.indication = indication
          expect(badge_status).to eq(status)
        end
      end
    end
  end

  describe "#language_code" do
    subject(:language_code) { check.send(:language_code) }

    {
      "fr" => "fr",
      "FR" => "fr",
      " fr-FR " => "fr",
      "FR-CA" => "fr",
      "fr_FR" => "fr",
      "en-US" => "en",
      "es-ES" => "es",
      "" => nil,
      nil => nil
    }.each do |indication, expected_code|
      context "when indication is #{indication.inspect}" do
        it "returns #{expected_code.inspect}" do
          check.indication = indication
          expect(language_code).to eq(expected_code)
        end
      end
    end
  end

  describe "#custom_badge_text" do
    subject(:badge_text) { check.send(:custom_badge_text) }

    {
      "fr-FR" => "fr-FR",
      "" => "",
      nil => described_class.human(:empty)
    }.each do |indication, text|
      context "when indication is #{indication.inspect}" do
        it "returns #{text.inspect}" do
          check.indication = indication
          expect(badge_text).to eq(text)
        end
      end
    end
  end
end
