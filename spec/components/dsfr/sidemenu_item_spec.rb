require "rails_helper"

RSpec.describe Dsfr::SidemenuItemComponent, type: :component do
  let(:href) { "/test-page" }
  let(:text) { "Test Page" }
  let(:active) { nil }
  let(:component) { described_class.new(href:, text:, active:) }
  let(:rendered_component) { render_inline(component) }

  describe "rendering" do
    it "renders a list item with the proper classes" do
      expect(rendered_component.css("li.fr-sidemenu__item")).to be_present
    end

    it "renders a link with the proper attributes" do
      link = rendered_component.css("a.fr-sidemenu__link").first
      expect(link).to be_present
      expect(link["href"]).to eq(href)
      expect(link.text).to eq(text)
    end
  end

  describe "active state" do
    context "when active is explicitly set to true" do
      let(:active) { true }

      it "adds the active class to the list item" do
        expect(rendered_component.css("li.fr-sidemenu__item--active")).to be_present
      end

      it "sets aria-current attribute on the link" do
        expect(rendered_component.css("a[aria-current='page']")).to be_present
      end
    end

    context "when active is explicitly set to false" do
      let(:active) { false }

      it "does not add the active class to the list item" do
        expect(rendered_component.css("li.fr-sidemenu__item--active")).not_to be_present
      end

      it "does not set aria-current attribute on the link" do
        expect(rendered_component.css("a[aria-current]")).not_to be_present
      end
    end

    context "when active is not set" do
      before do
        helpers = instance_double(ActionView::Helpers::UrlHelper, current_page?: current_page)
        allow(component).to receive(:helpers).and_return(helpers)
      end

      context "and the current page matches the href" do
        let(:current_page) { true }

        it "adds the active class to the list item" do
          expect(rendered_component.css("li.fr-sidemenu__item--active")).to be_present
        end

        it "sets aria-current attribute on the link" do
          expect(rendered_component.css("a[aria-current='page']")).to be_present
        end
      end

      context "and the current page does not match the href" do
        let(:current_page) { false }

        it "does not add the active class to the list item" do
          expect(rendered_component.css("li.fr-sidemenu__item--active")).not_to be_present
        end

        it "does not set aria-current attribute on the link" do
          expect(rendered_component.css("a[aria-current]")).not_to be_present
        end
      end
    end
  end
end
