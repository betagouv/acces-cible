# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper do
  describe "#icon" do
    it "handles any number of icon segments", :aggregate_failures do
      selector = ".fr-icon-user-fill"
      expect(helper.icon("user")).to have_selector(selector)
      expect(helper.icon(:user)).to have_selector(selector)

      selector = ".fr-icon-arrow-right-s-fill"
      expect(helper.icon("arrow", "right", "s")).to have_selector(selector)
      expect(helper.icon(["arrow", "right", "s"])).to have_selector(selector)
    end

    it "adds fill style unless told otherwise", :aggregate_failures do
      user_fill = ".fr-icon-user-fill"
      expect(helper.icon("user")).to have_selector(user_fill)
      expect(helper.icon("user", fill: true)).to have_selector(user_fill)

      user_line = ".fr-icon-user-line"
      expect(helper.icon("user", line: true)).to have_selector(user_line)
      expect(helper.icon("user", fill: false)).to have_selector(user_line)
      expect(helper.icon("user", line: true, fill: true)).to have_selector(user_line)
    end

    it "allows changing the tag", :aggregate_failures do
      expect(helper.icon("user")).to have_selector("span")
      expect(helper.icon("user", tag: :i)).to have_selector("i")
      expect(helper.icon("user", tag: "div")).to have_selector("div")
    end

    it "accepts additional HTML options", :aggregate_failures do
      expect(helper.icon("user", class: "custom-class")).to have_selector(".fr-icon-user-fill.custom-class")

      result = helper.icon("user", id: "icon-id", data: { test: "value" })
      expect(result).to have_selector("#icon-id[data-test='value']")
    end

    it "has aria-hidden: true, but allows overrides and additions", :aggregate_failures do
      expect(helper.icon("user")).to have_selector("[aria-hidden='true']")

      result = helper.icon("user", aria: { hidden: false })
      expect(result).to have_selector("span[aria-hidden='false']")

      result = helper.icon("user", aria: { label: "User icon" })
      expect(result).to have_selector("span[aria-hidden='true'][aria-label='User icon']")
    end

    it "accepts text as an option or a block", :aggregate_failures do
      result = helper.icon("user", text: "User Account")
      expect(result).to have_selector("span", text: "User Account")

      result = helper.icon("user", text: "<strong>User</strong>".html_safe)
      expect(result).to have_selector("span strong", text: "User")

      result = helper.icon("user") { "<strong>User</strong>".html_safe }
      expect(result).to have_selector("span strong", text: "User")

      result = helper.icon("user", text: "Option Text") { "Block Text" }
      expect(result).to have_text("Block Text")
      expect(result).not_to have_text("Option Text")
    end
  end

  describe "#icon_class" do
    it "handles any number of icon segments", :aggregate_failures do
      classes = "fr-icon-user-fill"
      expect(helper.icon_class("user")).to eq(classes)
      expect(helper.icon_class(:user)).to eq(classes)

      classes = "fr-icon-arrow-right-s-fill"
      expect(helper.icon_class("arrow", "right", "s")).to eq(classes)
      expect(helper.icon_class(["arrow", "right", "s"])).to eq(classes)
    end

    it "adds fill style unless told otherwise", :aggregate_failures do
      user_fill = "fr-icon-user-fill"
      expect(helper.icon_class("user")).to eq(user_fill)
      expect(helper.icon_class("user", fill: true)).to eq(user_fill)

      user_line = "fr-icon-user-line"
      expect(helper.icon_class("user", line: true)).to eq(user_line)
      expect(helper.icon_class("user", fill: false)).to eq(user_line)
      expect(helper.icon_class("user", line: true, fill: true)).to eq(user_line)
    end

    context "with side option" do
      it "adds link classes when side is specified", :aggregate_failures do
        expect(helper.icon_class(:arrow, side: :right)).to include("fr-link")
        expect(helper.icon_class(:arrow, side: :right)).to include("fr-link--icon-right")
        expect(helper.icon_class(:arrow, side: "right")).to include("fr-link--icon-right")
      end

      it "adds size modifier when provided" do
        expect(helper.icon_class(:arrow, side: :right, size: :sm)).to include("fr-link--sm")
      end

      it "ignores invalid side values" do
        expect(helper.icon_class(:arrow, side: :top)).not_to include("fr-link--icon")
      end

      it "ignores invalid size values" do
        expect(helper.icon_class(:arrow, side: :right, size: :xl)).not_to include("fr-link--xl")
      end
    end

    context "with button/btn option" do
      it "adds button classes when button: true is passed" do
        expect(helper.icon_class(:user, btn: true)).to include("fr-btn")
        expect(helper.icon_class(:user, button: true)).to include("fr-btn")
        expect(helper.icon_class(:user, button: true)).not_to include("fr-link")
      end

      it "adds size modifier when provided" do
        expect(helper.icon_class(:arrow, button: true, size: :sm)).to include("fr-btn--sm")
      end

      it "adds side modifier when provided" do
        expect(helper.icon_class(:arrow, button: true, side: :right)).to include("fr-btn--icon-right")
      end

      it "ignores invalid side values" do
        expect(helper.icon_class(:arrow, button: true, side: :top)).not_to include("fr-btn--icon")
      end

      it "ignores invalid size values" do
        expect(helper.icon_class(:arrow, button: true, side: :right, size: :xl)).not_to include("fr-btn--xl")
      end

      it "prioritizes button over link when both options are passed" do
        result = helper.icon_class(:arrow, button: true, side: :right)
        expect(result).to include("fr-btn--icon-right")
        expect(result).not_to include("fr-link")
      end
    end

    it "accepts a class option" do
      result = helper.icon_class(:arrow, class: "custom-class")
      expect(result).to include("custom-class")
    end
  end

  describe "#link_icon" do
    context "with name and options arguments" do
      it "generates a link with icon classes" do
        result = helper.link_icon(:arrow, "Next Page", "/next", side: :right)

        expect(result).to have_selector("a[href='/next']")
        expect(result).to have_selector("a.fr-link.fr-link--icon-right.fr-icon-arrow-fill")
        expect(result).to have_content("Next Page")
      end

      it "supports line style" do
        result = helper.link_icon(:arrow, "Next", "/next", line: true)

        expect(result).to have_selector("a.fr-icon-arrow-line")
      end

      it "supports size option" do
        result = helper.link_icon(:arrow, "Next", "/next", side: :right, size: :sm)

        expect(result).to have_selector("a.fr-link--sm")
      end

      it "supports button styling" do
        result = helper.link_icon(:arrow, "Next", "/next", button: true)

        expect(result).to have_selector("a.fr-btn")
        expect(result).not_to have_selector("a.fr-link")
      end

      it "merges custom classes" do
        result = helper.link_icon(:arrow, "Next", "/next", class: "my-custom-class")

        expect(result).to have_selector("a.my-custom-class")
        expect(result).to have_selector("a.fr-icon-arrow-fill")
      end
    end

    context "with block syntax" do
      it "generates a link with block content" do
        result = helper.link_icon(:arrow, "/next", side: :right) do
          helper.content_tag(:span, "Next Page", class: "visually-hidden")
        end

        expect(result).to have_selector("a[href='/next']")
        expect(result).to have_selector("a.fr-link.fr-link--icon-right.fr-icon-arrow-fill")
        expect(result).to have_selector("a span.visually-hidden", text: "Next Page")
      end

      it "supports all icon options with block syntax" do
        result = helper.link_icon(:download, "/file", button: true, size: :lg, side: :left) { "Download File" }

        expect(result).to have_selector("a.fr-btn.fr-btn--lg.fr-btn--icon-left.fr-icon-download-fill")
        expect(result).to have_content("Download File")
      end
    end
  end

  describe "#sortable_header" do
    subject(:sortable_header) { helper.sortable_header("Name", column, **options) }

    let(:column) { :name }
    let(:direction) { :asc }
    let(:options) { {} }
    let(:params) { { page: 2 } }

    before do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(**params))
      allow(helper).to receive(:url_for) { |options| "/?#{options[:params].to_query}" }

      allow(helper).to receive(:t).with("shared.asc").and_return("ascending")
      allow(helper).to receive(:t).with("shared.desc").and_return("descending")
      allow(helper).to receive(:t).with("shared.sort_by", any_args).and_return("Sort by #{column.capitalize} #{helper.t("shared.#{direction}")}")

      allow(helper).to receive(:icon_class).with(any_args).and_return("icon-class")
    end

    context "when no current sort exists", :aggregate_failures do
      it "generates a link with ascending sort parameter" do
        expect(sortable_header).to have_selector("a[href='/?page=2&sort%5Bname%5D=asc']")
        expect(sortable_header).to have_text("Name")
        expect(sortable_header).not_to include("fr-icon-arrow")
        expect(sortable_header).to have_selector("a[title='Sort by Name ascending']")
      end
    end

    context "when column is currently sorted ascending", :aggregate_failures do
      let(:direction) { :desc }
      let(:params) { { page: 2, sort: { name: "asc" } } }

      it "generates a link to sort descending" do
        expect(sortable_header).to have_selector("a[href*='sort%5Bname%5D=desc']")
        expect(sortable_header).to have_selector("a.icon-class")
        expect(sortable_header).to have_selector("a[title='Sort by Name descending']")
      end
    end

    context "when column is currently sorted descending", :aggregate_failures do
      let(:params) { { page: 2, sort: { name: "desc" } } }

      it "generates a link to sort ascending" do
        expect(sortable_header).to have_selector("a[href*='sort%5Bname%5D=asc']")
        expect(sortable_header).to have_selector("a.icon-class")
        expect(sortable_header).to have_selector("a[title='Sort by Name ascending']")
      end
    end

    context "with custom options", :aggregate_failures do
      let(:params) { { sort: { name: "asc" } } }
      let(:options) { { id: "sort-name", title: "Custom sort title", data: { test: "value" } } }

      it "adds HTML attributes to the link" do
        expect(sortable_header).to have_selector("a#sort-name")
        expect(sortable_header).to have_selector("a[title='Custom sort title']")
        expect(sortable_header).to have_selector("a[data-test='value']")
      end
    end

    context "when the page is currently sorted by a column", :aggregate_failures do
      let(:params) { { sort: { name: "asc", email: "desc" } } }

      it "allows sorting by another column" do
        sortable_header = helper.sortable_header("Name", :name)
        expect(sortable_header).to have_selector("a[href*='sort%5Bname%5D=desc']")

        sortable_header = helper.sortable_header("Email", :email)
        expect(sortable_header).to have_selector("a[href*='sort%5Bemail%5D=asc']")
      end
    end
  end
end
