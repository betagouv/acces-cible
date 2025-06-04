# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dsfr::TooltipComponent, type: :component do
  let(:text) { "Text" }
  let(:title) { "Title" }
  let(:type) { nil }
  let(:component) { described_class.new(text, title:, type:) }
  let(:rendered_component) { render_inline(component) }
  let(:id) { "tooltip-#{component.object_id}" }

  describe "rendering" do
    let(:span_attributes) { "[role=tooltip][aria-hidden=true][id=#{id}]" }
    let(:toggler_attributes) { "[id=#{id}-opener][aria-describedby=#{id}]" }

    context "when type is button (default)" do
      it "renders a button followed by a tooltip span" do
        expect(rendered_component).to have_css("button.fr-btn.fr-btn--tooltip[type=button]#{toggler_attributes}", text:)
        expect(rendered_component).to have_css("span.fr-tooltip.fr-placement#{span_attributes}", text: title)
        expect(rendered_component).to have_css("button.fr-btn + span.fr-tooltip")
      end
    end

    context "when type is link" do
      let(:type) { :link }

      it "renders a link followed by a tooltip span" do
        expect(rendered_component).to have_css("a.fr-link[tabindex=0][data-turbo=false]#{toggler_attributes}", text:)
        expect(rendered_component).to have_css("span.fr-tooltip.fr-placement#{span_attributes}", text: title)
        expect(rendered_component).to have_css("a.fr-link + span.fr-tooltip")
      end
    end
  end
end
