require "rails_helper"

RSpec.describe ApplicationComponent, type: :component do
  let(:component) { described_class.new }

  describe "#dom_id" do
    context "when object is nil" do
      it "uses the component's class and object_id" do
        expect(component.dom_id).to eq("application_component_#{component.object_id}")
      end
    end

    context "when object is a PORO" do
      let(:object) { Object.new }

      it "uses the object class name and object_id" do
        expect(component.dom_id(object)).to eq("object_#{object.object_id}")
      end
    end

    context "when object is an ApplicationRecord object" do
      let(:record) { User.new(id: 123) }

      it "uses the object's model_name and param" do
        expect(component.dom_id(record)).to eq("user_123")
      end
    end

    context "when object is namespaced" do
      let(:namespaced_object) { Dsfr::PaginationComponent.new(pagy: double) }

      it "replaces '::' with '_' in class name" do
        expect(component.dom_id(namespaced_object)).to eq("dsfr_pagination_component_#{namespaced_object.object_id}")
      end
    end

    context "when called with prefix and suffix options" do
      let(:object) { Object.new }

      it "includes prefix and suffix and removes invalid id characters" do
        expect(component.dom_id(object, prefix: "PRE:FIX", suffix: "SU/FFIX")).to eq("prefix_object_#{object.object_id}_suffix")
      end
    end
  end
end
