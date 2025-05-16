# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dsfr::TableComponent, type: :component do
  subject(:component) { described_class.new(**params) }

  let(:pagy) { instance_double(Pagy, page: 1, last: 1, count: 10, series: []) }
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

  describe "initialize" do
    context "when caption is not provided" do
      let(:params) { { pagy: } }

      it "raises an ArgumentError" do
        expect { component }.to raise_error(ArgumentError, /missing keyword: :caption/)
      end
    end

    context "when pagy is not provided" do
      let(:params) { { caption: } }

      it "raises an ArgumentError" do
        expect { component }.to raise_error(ArgumentError, /missing keyword: :pagy/)
      end
    end

    context "when HTML attributes are provided" do
      let(:params) { { caption:, pagy:, html_attributes: { class: "custom-class", id: "test-table" } } }

      it "applies HTML attributes to the table element" do
        expect(rendered_component).to have_css("div.fr-table.custom-class#test-table table")
      end
    end

    [:sm, :md, :lg, :xl].each do |size|
      context "when size option is :#{size}" do
        let(:params) { { caption:, pagy:, size: } }

        if size == :xl
          it "raises an ArgumentError" do
            expect { component }.to raise_error(ArgumentError, /size must be one of: sm, md, lg/)
          end
        else
          it "renders with correct size class" do
            if size == :md
              expect(rendered_component).not_to have_css("div.fr-table--#{size}")
            else
              expect(rendered_component).to have_css("div.fr-table--#{size}")
            end
          end
        end
      end
    end

    {
      hidden: "fr-table--no-caption",
      bottom: "fr-table--caption-bottom"
    }.each do |caption_side, expected_css|
      context "when caption_side is :#{}" do
        let(:params) { { caption:, pagy:, caption_side: } }

        it "contains 'div.#{expected_css}" do
          expect(rendered_component).to have_css("div.#{expected_css}")
        end
      end
    end

    [true, false].each do |border|
      context "when border is #{border}" do
        let(:params) { { caption:, pagy:, border: } }

        if border
          it "has the border class" do
            expect(rendered_component).to have_css("div.fr-table--border")
          end
        else
          it "doesn't have the border class" do
            expect(rendered_component).not_to have_css("div.fr-table--border")
          end
        end
      end
    end

    [true, false].each do |scroll|
      context "when scroll is #{scroll}" do
        let(:params) { { caption:, pagy:, scroll: } }

        if scroll
          it "doesn't have the no-scroll class" do
            expect(rendered_component).not_to have_css("div.fr-table--no-scroll")
          end
        else
          it "has the no-scroll class" do
            expect(rendered_component).to have_css("div.fr-table--no-scroll")
          end
        end
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
      allow(component).to receive(:human).with(:lines, count: 10).and_return("100 lines") # rubocop:disable RSpec/SubjectStub
    end

    it "displays the correct number of total lines" do
      expect(rendered_component).to have_css("div.fr-table__footer--start p.fr-table__detail", text: "100 lines")
    end
  end

  describe "pagination?" do
    let(:pagination_component) { instance_double(Dsfr::PaginationComponent) }

    [true, false].each do |value|
      context "when pagination_component returns #{value}" do
        before do
          allow(Dsfr::PaginationComponent).to receive(:new).with(pagy:).and_return(pagination_component)
          allow(pagination_component).to receive_messages(render?: value)
        end

        it "returns #{value}" do
          expect(component.send(:pagination?)).to be value
        end
      end
    end
  end

  describe "pagination" do
    let(:pagy) { instance_double(Pagy, last: 10, page: 1, prev: nil, next: 2, series: ["1", 2, 3, :gap, 10], vars: {}, count: 100) }

    it "renders the pagination component inside the table footer" do
      expect(rendered_component).to have_css("div.fr-table__footer--middle nav.fr-pagination")
    end
  end

  describe "footer_actions" do
    it "renders footer actions in the end footer section" do
      render_inline(component) do |c|
        c.with_footer_action { '<button class="fr-btn">Action 1</button>'.html_safe }
        c.with_footer_action { '<button class="fr-btn">Action 2</button>'.html_safe }
      end

      expect(rendered_component).to have_css("div.fr-table__footer--end") do |footer_end|
        expect(footer_end).to have_css("ul.fr-btns-group") do |buttons_group|
          expect(buttons_group).to have_css("li button.fr-btn", text: "Action 1")
          expect(buttons_group).to have_css("li button.fr-btn", text: "Action 2")
        end
      end
    end

    it "does not render the end footer section when no footer actions are provided" do
      expect(rendered_component).not_to have_css("div.fr-table__footer--end")
    end
  end

  describe "footer_actions?" do
    it "returns true when footer actions are provided" do
      component_with_actions = component
      component_with_actions.with_footer_action { "Action" }

      expect(component_with_actions.send(:footer_actions?)).to be true
    end

    it "returns false when no footer actions are provided" do
      expect(component.send(:footer_actions?)).to be false
    end
  end
end
