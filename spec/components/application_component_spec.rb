require "rails_helper"

RSpec.describe ApplicationComponent do
  # Create a test component class to test the behavior
  let(:test_component_class) do
    Class.new(ApplicationComponent) do
      def self.name
        "TestNamespace::ExampleComponent"
      end
    end
  end

  before do
    I18n.backend.store_translations(:fr, {
      viewcomponent: {
        test_namespace: {
          example: {
            title: "Titre",
            count: {
              one: "Un élément",
              other: "%{count} éléments"
            }
          },
          "example/status": {
            active: "Actif",
            inactive: "Inactif"
          }
        },
        generic_key: "Valeur globale",
        dsfr: {
          button: {
            label: "Bouton"
          }
        }
      },
      attributes: {
        fallback_key: "Valeur de fallback globale"
      }
    })
  end

  describe ".human" do
    context "with simple attribute" do
      it "looks up component-specific translation" do
        expect(test_component_class.human(:title)).to eq("Titre")
      end
    end

    context "with enum values using dot notation" do
      it "looks up enum translation by converting dots to slashes" do
        expect(test_component_class.human("status.active")).to eq("Actif")
        expect(test_component_class.human("status.inactive")).to eq("Inactif")
      end

      it "accepts symbol keys" do
        expect(test_component_class.human(:"status.active")).to eq("Actif")
      end

      it "converts dot notation to slash for I18n lookup" do
        expect(test_component_class.human("status.active")).to eq(
          I18n.t("viewcomponent.test_namespace.example/status.active")
        )
      end
    end

    context "with fallback chain" do
      it "falls back to generic viewcomponent scope when component-specific translation missing" do
        expect(test_component_class.human(:generic_key)).to eq("Valeur globale")
      end

      it "falls back to top-level attributes scope" do
        expect(test_component_class.human(:fallback_key)).to eq("Valeur de fallback globale")
      end

      it "falls back to provided default when all lookups fail" do
        expect(test_component_class.human(:missing_key, default: "Traduction spécifique")).to eq("Traduction spécifique")
      end
    end

    context "with count option" do
      it "handles pluralization" do
        expect(test_component_class.human(:count, count: 1)).to eq("Un élément")
        expect(test_component_class.human(:count, count: 3)).to eq("3 éléments")
      end

      it "defaults count to 1 when not provided" do
        expect(test_component_class.human(:count)).to eq("Un élément")
      end
    end

    context "with namespaced component" do
      it "converts namespace separators correctly" do
        # TestNamespace::ExampleComponent -> test_namespace.example
        expect(test_component_class.human(:title)).to eq("Titre")
      end

      it "strips _component suffix from name" do
        # The component name should have _component removed for I18n lookup
        namespaced = Class.new(ApplicationComponent) do
          def self.name
            "Dsfr::ButtonComponent"
          end
        end

        expect(namespaced.human(:label)).to eq("Bouton")
      end
    end
  end

  describe "#human" do
    it "delegates to class method" do
      component = test_component_class.new
      expect(component.human(:title)).to eq(test_component_class.human(:title))
    end

    it "works with enum values" do
      component = test_component_class.new
      expect(component.human("status.active")).to eq("Actif")
    end
  end
end
