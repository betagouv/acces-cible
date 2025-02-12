# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dsfr::TableComponent, type: :component do
  subject(:component) { described_class.new(**params) }

  let(:params) { { caption: "Test Table" } }

  it "renders the DSFR table structure" do
    render_inline(component)

    expect(page).to have_css("div.fr-table") do |table_wrapper|
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
    let(:params) { {} }

    it "raises an ArgumentError" do
      expect { component }.to raise_error(ArgumentError, /missing keyword: :caption/)
    end
  end

  context "when HTML attributes are provided" do
    let(:params) { { caption: "Test Table", html_attributes: { class: "custom-class", id: "test-table" } } }

    it "applies HTML attributes to the table element" do
      render_inline(component)

      expect(page).to have_css("table.custom-class#test-table")
    end
  end

  describe "size option" do
    [:sm, :md, :lg].each do |size|
      context "when size is :#{size}" do
        let(:params) { { caption: "Test Table", size: size } }
        it "renders with correct size class" do
          render_inline(component)
          if size == :md
            expect(page).not_to have_css("div.fr-table--#{size}")
          else
            expect(page).to have_css("div.fr-table--#{size}")
          end
        end
      end
    end

    context "with invalid size" do
      let(:params) { { caption: "Test Table", size: :xl } }

      it "raises an ArgumentError" do
        expect { component }.to raise_error(ArgumentError, /size must be one of: sm, md, lg/)
      end
    end
  end

  describe "border option" do
    context "when border is true" do
      let(:params) { { caption: "Test Table", border: true } }

      it "adds the border class" do
        render_inline(component)
        expect(page).to have_css("div.fr-table--border")
      end
    end

    context "when border is false" do
      let(:params) { { caption: "Test Table", border: false } }

      it "does not add the border class" do
        render_inline(component)
        expect(page).not_to have_css("div.fr-table--border")
      end
    end
  end

  describe "scroll option" do
    context "when scroll is false" do
      let(:params) { { caption: "Test Table", scroll: false } }

      it "adds the no-scroll class" do
        render_inline(component)
        expect(page).to have_css("div.fr-table--no-scroll")
      end
    end

    context "when scroll is true" do
      let(:params) { { caption: "Test Table", scroll: true } }

      it "does not add the no-scroll class" do
        render_inline(component)
        expect(page).not_to have_css("div.fr-table--no-scroll")
      end
    end
  end

  describe "slots" do
    it "renders the head slot content" do
      render_inline(component) do |c|
        c.with_head { "<tr><th>Header</th></tr>".html_safe }
      end

      expect(page).to have_css("thead tr th", text: "Header")
    end

    it "renders the body slot content" do
      render_inline(component) do |c|
        c.with_body { "<tr><td>Data</td></tr>".html_safe }
      end

      expect(page).to have_css("tbody tr td", text: "Data")
    end
  end
end
