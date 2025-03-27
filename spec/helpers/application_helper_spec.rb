# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
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
end
