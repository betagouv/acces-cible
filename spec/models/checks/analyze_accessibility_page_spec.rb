require "rails_helper"

RSpec.describe Checks::AnalyzeAccessibilityPage do
  let(:check) { described_class.send(:new) }

  describe ".analyze!" do
    let(:page) { build(:page, body:) }
    let(:text) do
      <<~HTML
        <p>… s’engage à rendre ses sites internet accessibles conformément à l’article 47 de la loi n° 2005-102 du 11 février 2005.</p>
        <p>Audit réalisé le 15 mars 2024 par la Société ABC, qui révèle que le site est à 75% conforme au RGAA version 4.1.</p>
      HTML
    end

    it "returns complete accessibility information" do
      allow(check).to receive(:page).and_return(build(:page, body: text))
      expect(check.send(:analyze!)).to include(
        audit_date: Date.new(2024, 3, 15),
        compliance_rate: 75,
        standard: "RGAA version 4.1",
        auditor: "ABC"
      )
    end
  end

  describe "#find_audit_date" do
    {
      "réalisé le 15 mars 2024" => Date.new(2024, 3, 15),
      "réalisée 1er février 2024" => Date.new(2024, 2, 1),
      "en mars 2024" => Date.new(2024, 3, 1),
      "loi n° 2005-102 du 11 février 2005… audit réalisé le 11 février 2025" => Date.new(2025, 2, 11),
      "du 15 février 2024" => Date.new(2024, 2, 15),
      "du 35 mai 2024" => nil
    }.each do |text, expected_date|
      it "extracts '#{expected_date ? I18n.l(expected_date, format: :compact) : nil}' from '#{text}'" do
        allow(check).to receive(:page).and_return(build(:page, body: text))
        expect(check.find_audit_date).to eq(expected_date)
      end
    end
  end

  describe "#find_compliance_rate" do
    {
      "avec un taux de conformité 81,25%" => 81.25,
      "taux de conformité de 75%" => 75,
      "conforme à 80,5%" => 80.5,
      "révèle que 90.5%" => 90.5,
      "taux de conformité globale est de 95 pour cent" => 95
    }.each do |text, expected_rate|
      it "extracts '#{expected_rate}%' from '#{text}'" do
        allow(check).to receive(:page).and_return(build(:page, body: text))
        expect(check.find_compliance_rate).to eq(expected_rate)
      end
    end
  end

  describe "#find_standard" do
    {
      "conforme au RGAA version 4.1." => "RGAA version 4.1",
      "les administrations, RGAA version 4.1.2, " => "RGAA version 4.1.2",
      "RGAA v4.1.1" => "RGAA v4.1.1",
      "au RGAA" => "RGAA",
      "des critères WCAG" => "WCAG"
    }.each do |text, expected_standard|
      it "extracts '#{expected_standard}' from '#{text}'" do
        allow(check).to receive(:page).and_return(build(:page, body: text))
        expect(check.find_standard).to eq(expected_standard)
      end
    end
  end

  describe "#find_auditor" do
    {
      "par la société ABC," => "ABC",
      "par XYZ (cabinet d'audit assermenté)," => "XYZ (cabinet d'audit assermenté)",
      "par Test Corp révèle" => "Test Corp",
      "par AXS Consulting sur un échantillon…" => "AXS Consulting"
    }.each do |text, expected_auditor|
      it "extracts '#{expected_auditor}' from '#{text}'" do
        allow(check).to receive(:page).and_return(build(:page, body: text))
        expect(check.find_auditor).to eq(expected_auditor)
      end
    end
  end
end
