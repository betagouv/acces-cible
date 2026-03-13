require "rails_helper"

RSpec.describe Checks::AnalyzeSchema do
  context "with common analyzer behaviors" do
    let(:href_years) { [Date.current.year - 1, Date.current.year + 1] }
    let(:href_text) { "Schema pluriannuel d'accessibilite" }
    let(:href_with_years) { "https://www.example.com/schema-#{href_years.join("-")}.pdf" }
    let(:text_years) { href_years }
    let(:text_with_years) { "Schema pluriannuel d'accessibilite #{href_years.join("-")}" }

    it_behaves_like "analyzes documents"
  end

  describe ".analyze!" do
    context "when looking for pattern" do
      let(:link_href) { "https://www.example.com/schema_pluriannuel.pdf" }

      it_behaves_like "matches document text", text: "schema pluriannuel #{Date.current.year - 1}-#{Date.current.year + 10}", expected: { years: [Date.current.year - 1, Date.current.year + 10], valid_years: false }
      it_behaves_like "matches document text", text: "schema annuel d'accessibilite #{Date.current.year - 5}", expected: { years: [Date.current.year - 5], valid_years: false }
      it_behaves_like "matches document text", text: "schema pluriannuel #{Date.current.year - 1}-#{Date.current.year + 1}", expected: { years: [Date.current.year - 1, Date.current.year + 1], valid_years: true }
      it_behaves_like "matches document text", text: "schema pluriannuel d'accessibilite numerique #{Date.current.year}", expected: { years: [Date.current.year], valid_years: true }
      it_behaves_like "matches document text", text: "schema pluriannuel de mise en accessibilite #{Date.current.year - 1}-#{Date.current.year + 1}", expected: { years: [Date.current.year - 1, Date.current.year + 1], valid_years: true }
      it_behaves_like "matches document text", text: "schema pluriannuel RGAA #{Date.current.year - 1}-#{Date.current.year + 1}", expected: { years: [Date.current.year - 1, Date.current.year + 1], valid_years: true }
      it_behaves_like "matches document text", text: "schema d'accessibilite pluriannuel #{Date.current.year - 1}-#{Date.current.year + 1}", expected: { years: [Date.current.year - 1, Date.current.year + 1], valid_years: true }
      it_behaves_like "matches document text", text: "schema annuel d'accessibilite #{Date.current.year}", expected: { years: [Date.current.year], valid_years: true }
      it_behaves_like "matches document text", text: "SCHEMA PLURIANNUEL D'ACCESSIBILITE #{Date.current.year}", expected: { years: [Date.current.year], valid_years: true }
    end

    context "when text does not match pattern" do
      it_behaves_like "does not match document text", text: "schema pluriannuel d'accessibillite numerique #{Date.current.year}"
      it_behaves_like "does not match document text", text: "schema annuel accessibilite #{Date.current.year}"
      it_behaves_like "does not match document text", text: "accessibilite - schema #{Date.current.year}"
    end
  end

  describe "#within_three_years?" do
    it_behaves_like "validates years", years: [Date.current.year], expected: true
    it_behaves_like "validates years", years: [Date.current.year - 1], expected: false
    it_behaves_like "validates years", years: [Date.current.year + 1], expected: false
    it_behaves_like "validates years", years: [Date.current.year - described_class::MAX_YEARS_VALIDITY, Date.current.year], expected: true
    it_behaves_like "validates years", years: [Date.current.year, Date.current.year + described_class::MAX_YEARS_VALIDITY], expected: true
    it_behaves_like "validates years", years: [Date.current.year - 1, Date.current.year + 1], expected: true
    it_behaves_like "validates years", years: [Date.current.year - described_class::MAX_YEARS_VALIDITY - 1, Date.current.year - 1], expected: false
    it_behaves_like "validates years", years: [Date.current.year + 1, Date.current.year + described_class::MAX_YEARS_VALIDITY + 1], expected: false
  end
end
