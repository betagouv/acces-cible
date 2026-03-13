require "rails_helper"

RSpec.describe FindAccessibilityPageService do
  subject(:service) { described_class.call(audit) }

  let(:root_url) { "https://example.com" }
  let(:home_page_html) { '<a href="/accessibilite">Accessibilité</a>' }
  let(:audit) { build(:audit, url: root_url, home_page_url: root_url, home_page_html: home_page_html) }

  describe ".call" do
    let(:matching_page_url) { "https://example.com/accessibility" }
    let(:matching_page_html) do
      "<html><body><h1>#{Checks::AccessibilityPageHeading.expected_headings[0]}</h1><h1>#{Checks::AccessibilityPageHeading.expected_headings[1]}</h1></body></html>"
    end
    let(:matching_page) { instance_double(Page, url: matching_page_url, html: matching_page_html, headings: Checks::AccessibilityPageHeading.expected_headings.first(2)) }
    let(:crawler) { instance_double(Crawler) }

    before do
      allow(Crawler).to receive(:new).and_return(crawler)
      allow(audit).to receive(:update_accessibility_page!)
    end

    context "when a valid accessibility page is found" do
      it "finds and updates the accessibility page" do
        allow(crawler).to receive(:find_page).and_return(matching_page)

        described_class.call(audit)

        expect(audit).to have_received(:update_accessibility_page!).with(matching_page_url, matching_page_html)
      end
    end

    context "when prioritizing links" do
      let(:home_page_html) do
        <<-HTML
          <html lang="fr">
            <body>
              <a href="/contact">Contact</a>
              <a href="/accessibilite">Accessibilité</a>
              <a href="/rgaa">RGAA</a>
              <a href="/declaration">Déclaration d'accessibilité</a>
              <a href="/declaration-accessibilite">Accessibilité : non conforme</a>
            </body>
          </html>
        HTML
      end

      let(:expected_link_list) { %w[https://example.com/declaration-accessibilite https://example.com/accessibilite https://example.com/declaration https://example.com/rgaa] }

      it "prioritizes links correctly in the crawler" do
        allow(Crawler).to receive(:new).with(
          root_url,
          root_page_html: home_page_html,
          queue: LinkList.new(expected_link_list)
        ).and_return(crawler)

        allow(crawler).to receive(:find_page).and_return(nil)

        described_class.call(audit)

        expect(Crawler).to have_received(:new).with(
          root_url,
          root_page_html: home_page_html,
          queue: LinkList.new(expected_link_list)
        )
      end
    end

    it "does nothing if no page is found" do
      allow(crawler).to receive(:find_page).and_return(nil)

      described_class.call(audit)

      expect(audit).not_to have_received(:update_accessibility_page!)
    end
  end

  describe ".enqueue_children" do
    let(:audit) { build(:audit, url: "https://example.com", home_page_url: "https://www.example.com/redirection") }
    let(:queue) { LinkList.new }
    let(:page) { instance_double(Page, url: "https://example.com/a") }
    let(:links) do
      [
        Link.new(href: "https://example.com/", text: "home url"),
        Link.new(href: "https://example.com/redirection", text: "redirection url"),
        Link.new(href: "https://example.com/a11y", text: "a11y"),
        Link.new(href: "https://example.com/a", text: "ah")
      ]
    end

    before do
      allow(page).to receive(:internal_links).and_return(links)
      allow(described_class).to receive(:links_by_priority) { |incoming_links| incoming_links }
    end

    it "does not enqueues home, redirection and page url" do
      described_class.send(:enqueue_children, page, queue, audit)

      expect(queue.to_a).to eq(["https://example.com/a11y"])
    end
  end
end
