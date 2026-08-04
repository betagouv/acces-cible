require "rails_helper"

RSpec.describe Checks::AnalyzeAccessibilityPage do
  let(:check) { described_class.new }
  let(:body) { "" }
  let(:accessibility_page) { build(:page, body:) }

  before do
    allow(check).to receive(:audit).and_return(instance_double(Audit, page_for: accessibility_page))
  end

  describe ".analyze!" do
    let(:body) do
      <<~HTML
        <p>… s’engage à rendre ses sites internet accessibles conformément à l’article 47 de la loi n° 2005-102 du 11 février 2005.</p>
        <h2>Résultats des tests</h2>
        <p>Audit réalisé le 15 mars 2024 par la Société ABC, qui révèle que le site est à 75% conforme au RGAA version 4.1.</p>
        <h2>Contenus non accessibles</h2>
      HTML
    end

    it "returns complete accessibility information" do
      expect(check.send(:analyze!)).to include(
                                         audit_date: Date.new(2024, 3, 15),
                                         compliance_rate: 75,
                                         standard: "RGAA version 4.1",
                                         auditor: "ABC",
                                         mentions_article: true
                                       )
    end
  end

  describe "#find_contact_email" do
    context "when email is between two correct headings" do
      context "when email is in text" do
        {
          "Contact : jessie@frazelle.com " => "jessie@frazelle.com",
          "Contact : jessie(at)frazelle.com " => "jessie@frazelle.com",
          "Contact : jessie@frazelle.com, emily@xie.com" => "jessie@frazelle.com",
          "Contact : @emilyxie.com" => nil,
        }.each do |text, expected_email|
          context "with '#{text}'" do
            let(:body) { "<h1>Retour d'information et contact</h1><p>#{text}</p><h2>Autre</h2>" }

            it "extracts '#{expected_email}'" do
              expect(check.find_contact_email).to eq(expected_email)
            end
          end
        end
      end

      context "when email is a mailto" do
        [
          {
            text: "Contactez-nous",
            href: "mailto:emily@xie.com",
            expected_result: "emily@xie.com"
          },
          {
            text: "Parlons-en",
            href: "mailto:@xie.com",
            expected_result: nil
          }
        ].each do |test_case|
          context "with text='#{test_case[:text]}' and href='#{test_case[:href]}'" do
            let(:body) do
              <<~HTML
                <h2>Retour d'information et contact</h2>
                <a href="#{test_case[:href]}">#{test_case[:text]}</a>
                <h2>Voies de recours</h2>
              HTML
            end

            it "returns #{test_case[:expected_result]}" do
              expect(check.find_contact_email).to eq(test_case[:expected_result])
            end
          end
        end
      end

      context "when the mailto has no parameters" do
        let(:body) do
          <<~HTML
            <h2>Retour d'information et contact</h2>
            <p><a href="mailto:jessie@frazelle.com?subject=Accessibilite">Nous ecrire</a></p>
            <h2>Autre</h2>
          HTML
        end

        it "extracts an email from a mailto href" do
          expect(check.find_contact_email).to eq("jessie@frazelle.com")
        end
      end
    end

    context "when email is between the wrong headings" do
      context "when the email is in the text" do
        let(:body) do
          <<~HTML
            <h2>État de conformité</h2>
            <p>emily@xie.com</p>
            <h2>Résultats des tests</h2>
          HTML
        end

        it "does not extract the email from the text" do
          expect(check.find_contact_email).to be_nil
        end
      end

      context "when the email is in a mailto" do
        let(:body) do
          <<~HTML
            <h2>État de conformité</h2>
                <a href="mailto:emily@xie.com">Email de contact</a>
            <h2>Résultats des tests</h2>
          HTML
        end

        it "does not extract the email from the mailto" do
          expect(check.find_contact_email).to be_nil
        end
      end
    end
  end

  describe "#find_contact_form" do
    [
      {
        text: "Besoin d'aide ?",
        href: "/demarches/42",
        expected_result: "https://www.example.com/demarches/42"
      },
      {
        text: "Parlons-en",
        href: "/demarches/formulaire-contact",
        expected_result: "https://www.example.com/demarches/formulaire-contact"
      },
      {
        text: "Contactez-nous",
        href: "/demarches/42",
        expected_result: "https://www.example.com/demarches/42"
      },
      {
        text: "Demande d'assistance",
        href: "/aide",
        expected_result: "https://www.example.com/aide"
      },
      {
        text: "Demande d'assistance",
        href: "https://www.example123.com/aide",
        expected_result: "https://www.example123.com/aide"
      },
      {
        text: "Parlons-en",
        href: "/demarches/42",
        expected_result: nil
      },
      {
        text: "Contactez-nous",
        href: "mailto:jessie@frazelle.com",
        expected_result: nil
      },
    ].each do |test_case|
      context "with text='#{test_case[:text]}' and href='#{test_case[:href]}'" do
        let(:body) do
          <<~HTML
            <h2>Retour d'information et contact</h2>
            <p><a href="#{test_case[:href]}">#{test_case[:text]}</a></p>
            <h2>Voies de recours</h2>
          HTML
        end

        it "returns #{test_case[:expected_result]}" do
          expect(check.find_contact_form).to eq(test_case[:expected_result])
        end
      end
    end

    context "when the link is after the next heading" do
      let(:body) do
        <<~HTML
          <h2>Retour d'information et contact</h2>
          <p>Emily Xie</p>
          <h2>Voies de recours</h2>
          <p><a href="/formulaire-contact">Formulaire de contact</a></p>
        HTML
      end

      it "only searches links between the contact heading and the next heading" do
        expect(check.find_contact_form).to be_nil
      end
    end
  end

  describe "#find_audit_date" do
    {
      "réalisé le 15 mars 2024" => Date.new(2024, 3, 15),
      "réalisée 1er février 2024" => Date.new(2024, 2, 1),
      "en mars 2024" => Date.new(2024, 3, 1),
      "loi n° 2005-102 du 11 février 2005… audit réalisé le 11 février 2025" => Date.new(2025, 2, 11),
      "loi n° 2005-102 du 11 février 2005…" => nil,
      "du 15 février 2024" => Date.new(2024, 2, 15),
      "Cette déclaration a été établie le 1er janvier 2024, et mise à jour le 10 avril 2024" => Date.new(2024, 1, 1),
      "Cette déclaration a été établie le 3 juin 2020. Elle a été mise à jour le 4 novembre 2024." => Date.new(2020, 6, 3),
      "du 35 mai 2024" => nil,
      "Cette déclaration d'accessibilité s'applique au site ac-amiens.fr. Elle a été réalisée le 23 septembre 2020, sur la base des contenus disponibles à cette date." => Date.new(2020, 9, 23)
    }.each do |text, expected_date|
      context "with '#{text}'" do
        let(:body) { "<h1>État de conformité</h1><p>#{text}</p><h2>Autre</h2>" }

        it "extracts '#{expected_date ? I18n.l(expected_date, format: :compact) : nil}'" do
          expect(check.find_audit_date(Checks::AnalyzeAccessibilityPage::AUDIT_DATE_PATTERN)).to eq(expected_date)
        end
      end
    end

    context "when dates are scattered under different headers" do
      let(:body) do
        <<~HTML
          <p>Conformément à l’article 47 de la loi n° 2005-102 du 11 février 2005.</p>
          <h2>État de conformité</h2>
          <p>La déclaration a été réalisée le 23 septembre 2020.</p>
          <h2>Autre</h2>
          <p>Informations diverses du 11 février 2005.</p>
        HTML
      end

      it "only searches for dates with headers" do
        expect(check.find_audit_date(Checks::AnalyzeAccessibilityPage::AUDIT_DATE_PATTERN)).to eq(Date.new(2020, 9, 23))
      end
    end

    context "when the law's date also appears" do
      let(:body) do
        <<~HTML
          <h2>État de conformité</h2>
          <p>Conformément à la loi n° 2005-102 du 11 février 2005.</p>
          <p>La déclaration a été réalisée le 1er mars 2024</p>
          <h2>Autre</h2>
        HTML
      end

      it "ignores the law's date" do
        expect(check.find_audit_date(Checks::AnalyzeAccessibilityPage::AUDIT_DATE_PATTERN)).to eq(Date.new(2024, 3, 1))
      end
    end
  end

  describe "#find_audit_update_date" do
    {
      "Suite à un audit de recette effectué en interne par l'Expert Accessibilité de la DILA réalisé le 16 juin 2023, le taux de conformité au RGAA v 4.1 est dorénavant de 88,52 %." => nil,
      "Mise à jour le 7 mars 2024 suite à la correction de plusieurs non-conformités." => Date.new(2024, 3, 7),
      "Cette déclaration a été établie le 1er janvier 2024, et mise à jour le 10 avril 2024" => Date.new(2024, 4, 10),
      "Une mention de date qui n'a pas de mots-clés le 15 septembre 2024." => nil,
      "Une date invalide du 35 mai 2024 pour une mise à jour." => nil
    }.each do |text, expected_date|
      context "with '#{text}'" do
        let(:body) { "<h1>État de conformité</h1><p>#{text}</p><h2>Autre</h2>" }

        before do
          allow(check).to receive(:audit_date).and_return(expected_date ? expected_date - 1.year : nil)
        end

        it "extracts '#{expected_date ? I18n.l(expected_date, format: :compact) : nil}'" do
          expect(check.find_audit_date(Checks::AnalyzeAccessibilityPage::AUDIT_UPDATE_DATE_PATTERN)).to eq(expected_date)
        end
      end
    end
  end

  describe "#find_compliance_rate" do
    {
      "avec un taux de conformité 81,25%" => 81.25,
      "taux de conformité de 75%" => 75,
      "conforme à 80,5%" => 80.5,
      "révèle que 90.5%" => 90.5,
      "100% des critères RGAA sont respectés" => 100,
      "82 % des critères RGAA sont respectés [...] à 93 %" => 82,
      "le taux de conformité global était de 60,8% [...] le taux de conformité global est de 70,9%." => 70.9,
      "94,03% des critères RGAA sont respectés. Le taux moyen de conformité du service en ligne s’élève à 99%" => 94.03,
      "taux de conformité globale est de 95 pour cent" => 95,
      "Le taux global de conformité était de 51,43% en Juin 2023, mis à jour à 71,21% sur l’ensemble critères du référentiel générale d’amélioration de l’accessibilité (RGAA)." => 71.21,
      "Le taux de conformité global est de 74,6 %.
      Le taux de conformité moyen est de 87,4 %.
      Le taux de conformité global est de 83,1 %.
      Le taux de conformité moyen est de 89 %." => 83.1
    }.each do |text, expected_rate|
      context "with '#{text}'" do
        let(:body) do
          <<~HTML
            <h2>Résultats des tests</h2>
            <p>#{text}</p>
            <h2>Contenus non accessibles</h2>
          HTML
        end

        it "extracts '#{expected_rate}%'" do
          expect(check.find_compliance_rate).to eq(expected_rate)
        end
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
      context "with '#{text}'" do
        let(:body) { text }

        it "extracts '#{expected_standard}'" do
          expect(check.find_standard).to eq(expected_standard)
        end
      end
    end
  end

  describe "#find_auditor" do
    {
      "par la société ABC," => "ABC",
      "par XYZ (cabinet d'audit assermenté)," => "XYZ (cabinet d'audit assermenté)",
      "par Test Corp révèle" => "Test Corp",
      "par AXS Consulting sur un échantillon…" => "AXS Consulting",
      "L’audit de conformité réalisé par Koena révèle que :" => "Koena",
      "par ailleurs vous pouvez toujours compter sur nous" => nil,
      "réalisé par la société Empreinte Digitale" => "Empreinte Digitale",
      " l’ Agence Cosiweb" => "Cosiweb"
    }.each do |text, expected_auditor|
      context "with '#{text}'" do
        let(:body) do
          <<~HTML
            <h2>Résultats des tests</h2>
            <p>#{text}</p>
            <h2>Contenus non accessibles</h2>
          HTML
        end

        it "extracts '#{expected_auditor}'" do
          expect(check.find_auditor).to eq(expected_auditor)
        end
      end
    end
  end

  describe "#find_article_mention" do
    subject { check.send(:mentions_article) }

    {
      "article 47 loi n°2005-102 du 11 février 2005" => true,
      "art. 47 de la loi numéro 2005-102 du 11 fevrier 2005" => true,
      "Contactez-nous pour plus d'informations" => false,
      "" => false
    }.each do |text, expectation|
      context "with '#{text}'" do
        let(:body) { text }

        it "returns '#{expectation}'" do
          expect(check.find_article_mention).to eq(expectation)
        end
      end
    end
  end
end
