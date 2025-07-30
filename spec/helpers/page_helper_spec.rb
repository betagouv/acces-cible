require "rails_helper"

RSpec.describe PageHelper do
  describe "#head_title" do
    it "returns service info for root page" do
      allow(helper).to receive(:root?).and_return(true)

      result = helper.head_title
      expect(result).to eq("Accès cible : Contrôle l'accessibilité et la conformité des sites internet")
    end

    it "returns page title with service name for other pages" do
      allow(helper).to receive_messages(
                         root?: false,
                         page_title: "Test Page"
                       )

      result = helper.head_title
      expect(result).to eq("Test Page - Accès cible")
    end

    it "returns a truncated page title with service name for other pages" do
      allow(helper).to receive_messages(
                         root?: false,
                         page_title: "Test Page" * 10
                       )

      result = helper.head_title
      expect(result).to eq("Test PageTest PageTest PageTest PageTest PageTe... - Accès cible")
    end
  end

  describe "#page_actions" do
    it "generates a div with default DSFR button group classes" do
      result = helper.page_actions { "Some content" }

      expect(result).to have_selector("div.fr-btns-group.fr-btns-group--inline-md.fr-mb-2w")
      expect(result).to have_content("Some content")
    end

    it "accepts additional HTML attributes and merges custom classes with defaults", :aggregate_failures do
      result = helper.page_actions(id: "page-actions", data: { test: "value" }, class: "custom-class") { "Content" }

      expect(result).to have_selector("div#page-actions[data-test='value']")
      expect(result).to have_selector("div.fr-btns-group.fr-btns-group--inline-md.fr-mb-2w.custom-class")
    end

    it "allows yielding complex content" do
      result = helper.page_actions do
        helper.tag.a("Edit", href: "/edit", class: "fr-btn") +
          helper.tag.a("Delete", href: "/delete", class: "fr-btn fr-btn--secondary")
      end

      expect(result).to have_selector("div.fr-btns-group")
      expect(result).to have_selector("a[href='/edit'].fr-btn", text: "Edit")
      expect(result).to have_selector("a[href='/delete'].fr-btn.fr-btn--secondary", text: "Delete")
    end
  end
end
