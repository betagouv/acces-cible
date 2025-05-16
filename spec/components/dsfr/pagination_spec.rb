require "rails_helper"

RSpec.describe Dsfr::PaginationComponent, type: :component do
  subject(:component) { render_inline(described_class.new(pagy:)) }

  describe "render" do
    context "when there is only one page" do
      let(:pagy) { instance_double(Pagy, last: 1, page: 1, series: []) }

      it "returns no content" do
        expect(component.to_html).to be_empty
      end
    end

    context "when on the first page" do
      let(:pagy) { instance_double(Pagy, last: 10, page: 1, prev: nil, next: 2, series: ["1", 2, 3, :gap, 10], vars: {}) }

      it "renders the expected html" do
        expect(component).to have_css("nav.fr-pagination") do |wrapper|
          expect(wrapper).to have_css("ul.fr-pagination__list") do |container|
            expect(container).to have_css("a.fr-pagination__link--first[aria-disabled='true']")
            expect(container).to have_css("a.fr-pagination__link--prev[aria-disabled='true']")
            expect(container).to have_css("a.fr-pagination__link[aria-current='page']", text: "1")
            expect(container).to have_css("a.fr-pagination__link--next:not([aria-disabled])")
            expect(container).to have_css("a.fr-pagination__link--last:not([aria-disabled])")
          end
        end
      end
    end

    context "when in the middle of a series" do
      let(:pagy) { instance_double(Pagy, last: 10, page: 5, prev: 4, next: 6, series: [1, :gap, 4, "5", 6, :gap, 10], vars: {}) }

      it "renders the expected items" do
        expect(component).to have_css("a.fr-pagination__link--first:not([aria-disabled])")
        expect(component).to have_css("a.fr-pagination__link--prev:not([aria-disabled])")
        expect(component).to have_css("span.fr-pagination__link", text: "…")
        expect(component).to have_css("a.fr-pagination__link[aria-current='page']", text: "5")
        expect(component).to have_css("span.fr-pagination__link", text: "…")
        expect(component).to have_css("a.fr-pagination__link--next:not([aria-disabled])")
        expect(component).to have_css("a.fr-pagination__link--last:not([aria-disabled])")
      end
    end

    context "when on the last page" do
      let(:pagy) { instance_double(Pagy, last: 10, page: 10, prev: 9, next: nil, series: [1, :gap, 8, 9, "10"], vars: {}) }

      it "renders the expected items" do
        expect(component).to have_css("a.fr-pagination__link--first:not([aria-disabled])")
        expect(component).to have_css("a.fr-pagination__link--prev:not([aria-disabled])")
        expect(component).to have_css("a.fr-pagination__link[aria-current='page']", text: "10")
        expect(component).to have_css("a.fr-pagination__link--next[aria-disabled='true']")
        expect(component).to have_css("a.fr-pagination__link--last[aria-disabled='true']")
      end
    end
  end
end
