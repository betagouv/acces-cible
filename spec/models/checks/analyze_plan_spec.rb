require "rails_helper"

RSpec.describe Checks::AnalyzePlan do
  context "with common analyzer behaviors" do
    let(:href_years) { [Date.current.year] }
    let(:href_text) { "Plan annuel d'accessibilite" }
    let(:href_with_years) { "https://www.example.com/plan-annuel-#{Date.current.year}.pdf" }
    let(:text_years) { [Date.current.year + 1] }
    let(:text_with_years) { "Plan annuel d'accessibilite #{Date.current.year + 1}" }

    it_behaves_like "analyzes documents"
  end

  describe ".analyze!" do
    context "when looking for pattern" do
      let(:link_href) { "https://www.example.com/plan_annuel.pdf" }

      it_behaves_like "matches document text", text: "plan annuel d'accessibilite numerique #{Date.current.year}", expected: { years: [Date.current.year], valid_years: true }
      it_behaves_like "matches document text", text: "plan annuel d'accessibilite numerique #{Date.current.year - 5}", expected: { years: [Date.current.year - 5], valid_years: false }
      it_behaves_like "matches document text", text: "plan annuel de mise en accessibilite #{Date.current.year - 1}-#{Date.current.year}", expected: { years: [Date.current.year - 1, Date.current.year], valid_years: true }
      it_behaves_like "matches document text", text: "plan annuel de mise en accessibilite #{Date.current.year}-#{Date.current.year + 10}", expected: { years: [Date.current.year, Date.current.year + 10], valid_years: false }
      it_behaves_like "matches document text", text: "plan annuel #{Date.current.year}", expected: { years: [Date.current.year], valid_years: true }
      it_behaves_like "matches document text", text: "plan d'action #{Date.current.year + 1}", expected: { years: [Date.current.year + 1], valid_years: true }
      it_behaves_like "matches document text", text: "plan d'actions #{Date.current.year}-#{Date.current.year + 1}", expected: { years: [Date.current.year, Date.current.year + 1], valid_years: true }
      it_behaves_like "matches document text", text: "plan #{Date.current.year} d'action", expected: { years: [Date.current.year], valid_years: true }
      it_behaves_like "matches document text", text: "PLAN ANNUEL D'ACCESSIBILITE #{Date.current.year + 1}", expected: { years: [Date.current.year + 1], valid_years: true }
    end

    context "when text does not match pattern" do
      it_behaves_like "does not match document text", text: "plan d'accesibilite #{Date.current.year + 1}"
      it_behaves_like "does not match document text", text: "plan annuel mise accessibilite #{Date.current.year}"
      it_behaves_like "does not match document text", text: "plan accessibilite #{Date.current.year}"
    end
  end

  describe "#within_three_years?" do
    it_behaves_like "validates years", years: [Date.current.year + 2], expected: false
    it_behaves_like "validates years", years: [Date.current.year + 1], expected: true
    it_behaves_like "validates years", years: [Date.current.year], expected: true
    it_behaves_like "validates years", years: [Date.current.year - 1], expected: true
    it_behaves_like "validates years", years: [Date.current.year - 2], expected: false
  end
end
