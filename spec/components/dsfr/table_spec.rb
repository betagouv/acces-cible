# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dsfr::TableComponent, type: :component do
  subject(:component) { described_class.new(**params) }

  let(:pagy) { instance_double(Pagy, count: 100) }
  let(:caption) { "Test table" }
  let(:params) { { caption:, pagy: } }
  let(:rendered_component) { render_inline(component) }

  it "renders the DSFR table structure" do
    expect(rendered_component).to have_css("div.fr-table") do |table_wrapper|
      expect(table_wrapper).to have_css("div.fr-table__wrapper") do |inner_wrapper|
        expect(inner_wrapper).to have_css("div.fr-table__container") do |container|
          expect(container).to have_css("div.fr-table__content") do |content|
            expect(content).to have_css("table")
          end
        end
      end
    end
  end

  describe "when caption is not provided" do
    let(:params) { { pagy: } }

    it "raises an ArgumentError" do
      expect { component }.to raise_error(ArgumentError, /missing keyword: :caption/)
    end
  end

  describe "when pagy is not provided" do
    let(:params) { { caption: } }

    it "raises an ArgumentError" do
      expect { component }.to raise_error(ArgumentError, /missing keyword: :pagy/)
    end
  end

  context "when HTML attributes are provided" do
    let(:params) { { caption:, pagy:, html_attributes: { class: "custom-class", id: "test-table" } } }

    it "applies HTML attributes to the table element" do
      expect(rendered_component).to have_css("table.custom-class#test-table")
    end
  end

  describe "size option" do
    [:sm, :md, :lg].each do |size|
      context "when size is :#{size}" do
        let(:params) { { caption:, pagy:, size: } }

        it "renders with correct size class" do
          if size == :md
            expect(rendered_component).not_to have_css("div.fr-table--#{size}")
          else
            expect(rendered_component).to have_css("div.fr-table--#{size}")
          end
        end
      end
    end

    context "with invalid size" do
      let(:params) { { caption:, pagy:, size: :xl } }

      it "raises an ArgumentError" do
        expect { component }.to raise_error(ArgumentError, /size must be one of: sm, md, lg/)
      end
    end
  end

  describe "border option" do
    context "when border is true" do
      let(:params) { { caption:, pagy:, border: true } }

      it "adds the border class" do
        expect(rendered_component).to have_css("div.fr-table--border")
      end
    end

    context "when border is false" do
      let(:params) { { caption:, pagy:, border: false } }

      it "does not add the border class" do
        expect(rendered_component).not_to have_css("div.fr-table--border")
      end
    end
  end

  describe "scroll option" do
    context "when scroll is false" do
      let(:params) { { caption:, pagy:, scroll: false } }

      it "adds the no-scroll class" do
        expect(rendered_component).to have_css("div.fr-table--no-scroll")
      end
    end

    context "when scroll is true" do
      let(:params) { { caption:, pagy:, scroll: true } }

      it "does not add the no-scroll class" do
        expect(rendered_component).not_to have_css("div.fr-table--no-scroll")
      end
    end
  end

  describe "slots" do
    it "renders the head slot content" do
      render_inline(component) do |c|
        c.with_head { "<tr><th>Header</th></tr>".html_safe }
      end

      expect(rendered_component).to have_css("thead tr th", text: "Header")
    end

    it "renders the body slot content" do
      render_inline(component) do |c|
        c.with_body { "<tr><td>Data</td></tr>".html_safe }
      end

      expect(rendered_component).to have_css("tbody tr td", text: "Data")
    end
  end

  describe "total_lines" do
    before do
      allow(component).to receive(:human).with(:lines, count: 100).and_return("100 lines") # rubocop:disable RSpec/SubjectStub
    end

    it "displays the correct number of total lines" do
      expect(rendered_component).to have_css("div.fr-table__footer--start p.fr-table__detail", text: "100 lines")
    end
  end

  describe "pagination" do
    let(:pagination_component) { instance_double(Dsfr::PaginationComponent) }

    before do
      allow(Dsfr::PaginationComponent).to receive(:new).with(pagy:).and_return(pagination_component)
      allow(pagination_component).to receive_messages(to_s: '<div class="fr-pagination">Test Pagination</div>'.html_safe, render?: true)
    end

    it "creates a pagination component with the pagy object" do
      render_inline(component) do |c|
        c.with_pagination
      end

      expect(Dsfr::PaginationComponent).to have_received(:new).with(pagy:)
    end

    it "renders the pagination in the middle footer section" do
      render_inline(component) do |c|
        c.with_pagination
      end

      expect(rendered_component).to have_css("div.fr-table__footer--middle div.fr-pagination", text: "Test Pagination")
    end

    it "does not render the middle footer section when pagination is not used" do
      expect(rendered_component).not_to have_css("div.fr-table__footer--middle")
    end
  end

  describe "pagination?" do
    it "returns true when pagination is explicitly set" do
      component_with_pagination = component
      component_with_pagination.with_pagination

      expect(component_with_pagination.send(:pagination?)).to be true
    end
  end
end
