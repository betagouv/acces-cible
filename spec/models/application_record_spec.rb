require "rails_helper"

RSpec.describe ApplicationRecord do
  before do
    I18n.backend.store_translations(:fr, {
      activerecord: {
        attributes: {
          audit: {
            title: "Nom de l'audit",
            count: {
              one: "Une vérification",
              other: "%{count} vérifications"
            }
          },
          "audit/status": {
            pending: "En attente",
            passed: "Passé",
            mixed: "Intermédiaire",
            failed: "Échoué"
          },
          generic_attr: "Attribut générique"
        }
      },
      attributes: {
        fallback_attr: "Attribut de fallback"
      }
    })
  end

  describe ".human" do
    context "with simple attribute" do
      it "looks up attribute translation" do
        expect(Audit.human(:title)).to eq("Nom de l'audit")
      end
    end

    context "with enum values using dot notation" do
      it "looks up enum translation by converting dots to slashes" do
        expect(Audit.human("status.pending")).to eq("En attente")
        expect(Audit.human("status.passed")).to eq("Passé")
        expect(Audit.human("status.mixed")).to eq("Intermédiaire")
        expect(Audit.human("status.failed")).to eq("Échoué")
      end

      it "accepts symbol keys" do
        expect(Audit.human(:"status.pending")).to eq("En attente")
      end

      it "converts dot notation to slash for I18n lookup" do
        # Verifies that "status.pending" becomes "status/pending" for YAML lookup
        expect(Audit.human("status.pending")).to eq(I18n.t("activerecord.attributes.audit/status.pending"))
      end
    end

    context "with fallback chain" do
      it "falls back to generic activerecord.attributes scope when model-specific translation missing" do
        expect(Audit.human(:generic_attr)).to eq("Attribut générique")
      end

      it "falls back to top-level attributes scope" do
        expect(Audit.human(:fallback_attr)).to eq("Attribut de fallback")
      end

      it "falls back to provided default when all lookups fail" do
        expect(Audit.human(:missing_key, default: "Fallback custom")).to eq("Fallback custom")
      end
    end

    context "with count option" do
      it "handles pluralization" do
        expect(Audit.human(:count, count: 1)).to eq("Une vérification")
        expect(Audit.human(:count, count: 5)).to eq("5 vérifications")
      end

      it "defaults count to 1 when not provided" do
        expect(Audit.human(:count)).to eq("Une vérification")
      end
    end
  end

  describe "#human" do
    it "delegates to class method" do
      audit = build(:audit)
      expect(audit.human(:title)).to eq(Audit.human(:title))
    end

    it "works with enum values" do
      audit = build(:audit)
      expect(audit.human("status.pending")).to eq("En attente")
    end
  end
end
