require "rails_helper"

RSpec.describe Dsfr::SidemenuComponent, type: :component do
  let(:title) { "Title" }
  let(:component) { described_class.new(title:) }
  let(:rendered_component) { render_inline(component) }

  describe "rendering" do
    context "with no items" do
      it "renders nothing" do
        expect(rendered_component.to_s).to be_empty
      end
    end

    context "with items" do
      before do
        component.with_item(href: "/page1", text: "Page 1")
        component.with_item(href: "/page2", text: "Page 2")
      end

      it "renders the component" do
        expect(rendered_component.css(".fr-sidemenu")).to be_present
      end

      it "renders the title" do
        expect(rendered_component.css("#fr-sidemenu-title").text).to eq(title)
      end

      it "renders the default button text" do
        expect(rendered_component.css(".fr-sidemenu__btn").text.strip).to eq(Dsfr::SidemenuComponent::DEFAULT_BUTTON_TEXT)
      end

      it "renders the items" do
        expect(rendered_component.css(".fr-sidemenu__item").count).to eq(2)
        expect(rendered_component.css(".fr-sidemenu__link").first.text).to eq("Page 1")
        expect(rendered_component.css(".fr-sidemenu__link").last.text).to eq("Page 2")
      end
    end
  end

  describe "CSS classes" do
    before do
      component.with_item(href: "/page", text: "Page")
    end

    context "with default options" do
      it "renders with the base class" do
        expect(rendered_component.css(".fr-sidemenu")).to be_present
        expect(rendered_component.css(".fr-sidemenu--sticky")).not_to be_present
        expect(rendered_component.css(".fr-sidemenu--sticky-full-height")).not_to be_present
        expect(rendered_component.css(".fr-sidemenu--right")).not_to be_present
      end
    end

    context "with sticky option" do
      let(:component) { described_class.new(title: title, sticky: true) }

      it "adds the sticky class" do
        expect(rendered_component.css(".fr-sidemenu--sticky")).to be_present
      end
    end

    context "with full_height option" do
      let(:component) { described_class.new(title: title, full_height: true) }

      it "adds both sticky and full-height classes" do
        expect(rendered_component.css(".fr-sidemenu--sticky")).to be_present
        expect(rendered_component.css(".fr-sidemenu--sticky-full-height")).to be_present
      end
    end

    context "with right option" do
      let(:component) { described_class.new(title: title, right: true) }

      it "adds the right class" do
        expect(rendered_component.css(".fr-sidemenu--right")).to be_present
      end
    end

    context "with custom button text" do
      let(:button_text) { "Custom Button" }
      let(:component) { described_class.new(title: title, button: button_text) }

      it "renders the custom button text" do
        expect(rendered_component.css(".fr-sidemenu__btn").text.strip).to eq(button_text)
      end
    end
  end
end
