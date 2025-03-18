require "rails_helper"

RSpec.describe Dsfr::PaginationComponent, type: :component do
  let(:pagy) { instance_double(Pagy) }

  # Create a subclass to stub helpers provided by view_context in real-world usage
  let(:test_component_class) do
    Class.new(described_class) do
      def pagy_url_for(pagy, page)
        "/path?page=#{page}"
      end

      def link_to(text, path, **options)
        content_tag(:a, text, href: path, **options)
      end
    end
  end

  let(:component) { test_component_class.new(pagy:) }

  describe "#items" do
    before do
      allow(component).to receive_messages(first_page: "first_page", previous_page: "previous_page", series: ["page1", "page2"], next_page: "next_page", last_page: "last_page")
    end

    it "returns an array with all pagination items" do
      expect(component.items).to eq(["first_page", "previous_page", "page1", "page2", "next_page", "last_page"])
    end
  end

  describe "#first_page" do
    before do
      allow(component).to receive(:human).with(:first).and_return("First")
    end

    context "when on first page" do
      before do
        allow(pagy).to receive(:page).and_return(1)
      end

      it "returns a disabled link" do
        result = component.first_page
        expect(result).to have_css("a.fr-pagination__link.fr-pagination__link--first[aria-disabled='true']", text: "First")
        expect(result).not_to have_css("a[href]")
      end
    end

    context "when not on first page" do
      before do
        allow(pagy).to receive(:page).and_return(2)
      end

      it "returns an enabled link" do
        result = component.first_page
        expect(result).to have_css("a.fr-pagination__link.fr-pagination__link--first[href='/path?page=1']", text: "First")
        expect(result).not_to have_css("[aria-disabled]")
      end
    end
  end

  describe "#previous_page" do
    before do
      allow(pagy).to receive(:prev).and_return(1)
      allow(component).to receive(:human).with(:prev).and_return("Previous")
    end

    context "when on first page" do
      before do
        allow(pagy).to receive(:page).and_return(1)
      end

      it "returns a disabled link" do
        result = component.previous_page
        expect(result).to have_css("a.fr-pagination__link.fr-pagination__link--prev[aria-disabled='true']", text: "Previous")
        expect(result).not_to have_css("a[href]")
      end
    end

    context "when not on first page" do
      before do
        allow(pagy).to receive(:page).and_return(2)
      end

      it "returns an enabled link" do
        result = component.previous_page
        expect(result).to have_css("a.fr-pagination__link.fr-pagination__link--prev[href='/path?page=1']", text: "Previous")
        expect(result).not_to have_css("[aria-disabled]")
      end
    end
  end

  describe "#next_page" do
    before do
      allow(component).to receive(:human).with(:next).and_return("Next")
    end

    context "when on last page" do
      before do
        allow(pagy).to receive_messages(page: 5, next: nil)
      end

      it "returns a disabled link" do
        result = component.next_page
        expect(result).to have_css("a.fr-pagination__link.fr-pagination__link--next[aria-disabled='true']", text: "Next")
        expect(result).not_to have_css("a[href]")
      end
    end

    context "when not on last page" do
      before do
        allow(pagy).to receive_messages(page: 2, next: 3)
      end

      it "returns an enabled link" do
        result = component.next_page
        expect(result).to have_css("a.fr-pagination__link.fr-pagination__link--next[href='/path?page=3']", text: "Next")
        expect(result).not_to have_css("[aria-disabled]")
      end
    end
  end

  describe "#last_page" do
    before do
      allow(pagy).to receive(:last).and_return(5)
      allow(component).to receive(:human).with(:last).and_return("Last")
    end

    context "when on last page" do
      before do
        allow(pagy).to receive(:page).and_return(5)
      end

      it "returns a disabled link" do
        result = component.last_page
        expect(result).to have_css("a.fr-pagination__link.fr-pagination__link--last[aria-disabled='true']", text: "Last")
        expect(result).not_to have_css("a[href]")
      end
    end

    context "when not on last page" do
      before do
        allow(pagy).to receive(:page).and_return(2)
      end

      it "returns an enabled link" do
        result = component.last_page
        expect(result).to have_css("a.fr-pagination__link.fr-pagination__link--last[href='/path?page=5']", text: "Last")
        expect(result).not_to have_css("[aria-disabled]")
      end
    end
  end

  describe "#series" do
    let(:page_text) { "1" }

    before do
      allow(pagy).to receive(:series).and_return([:gap, page_text, 3])
      allow(component).to receive(:human).with(:page, page: page_text).and_return("Page 1")
      allow(component).to receive(:human).with(:page, page: 3).and_return("Page 3")
    end

    it "maps pagy series to appropriate HTML elements" do
      result = component.series

      # Check for gap element
      expect(result[0]).to have_css("span.fr-pagination__link", text: "…")

      # Check for current page
      expect(result[1]).to have_css("a.fr-pagination__link[aria-current='page']", text: page_text)
      expect(result[1]).to have_css("a[title='Page 1']")

      # Check for regular page
      expect(result[2]).to have_css("a.fr-pagination__link[href='/path?page=3']", text: "3")
      expect(result[2]).to have_css("a[title='Page 3']")
    end
  end
end
