require "rails_helper"

RSpec.describe Checks::LanguageIndication do
  let(:check) { described_class.new }

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
