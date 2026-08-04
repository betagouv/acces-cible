require "rails_helper"

RSpec.describe FindAccessibilityPageService do
  subject(:service) { described_class.new(audit) }

  let(:root_url) { "https://example.com" }
  let(:home_page_html) { '<a href="/accessibilite">Accessibilité</a>' }
  let(:site) { create(:site, url: root_url) }
  let(:audit) { create(:audit, :without_checks, site:, home_page_url: root_url) }

  describe ".call" do
    let(:matching_page_url) { "https://example.com/accessibility" }
    let(:matching_page_html) do
      "<html><body><h1>#{Checks::AccessibilityPageHeading.expected_headings[0]}</h1><h1>#{Checks::AccessibilityPageHeading.expected_headings[1]}</h1></body></html>"
    end
    let(:matching_page) do
      instance_double(Page,
                      url: matching_page_url,
                      actual_url: matching_page_url,
                      html: matching_page_html,
                      status: 200,
                      headings: Checks::AccessibilityPageHeading.expected_headings.first(2))
    end
    let(:crawler) { instance_double(Crawler) }

    before do
      create(:page_snapshot, audit:, kind: "home", html: home_page_html)
      allow(Crawler).to receive(:new).and_return(crawler)
    end

    context "when a valid accessibility page is found" do
      it "finds and updates the accessibility page" do
        allow(crawler).to receive(:find_page).and_return(matching_page)

        described_class.new(audit)

        expect(audit.reload.accessibility_page_url).to eq(matching_page_url)
      end

      it "stores a page snapshot with the fetched page's data" do
        allow(crawler).to receive(:find_page).and_return(matching_page)

        described_class.new(audit)

        expect(audit.page_snapshots.find_by(kind: "accessibility")).to have_attributes(
                                                                         requested_url: matching_page_url,
                                                                         current_url: matching_page_url,
                                                                         html: matching_page_html,
                                                                         status: 200
                                                                       )
      end
    end

    context "when prioritizing links" do
      let(:home_page_html) do
        <<-HTML
          <html lang="fr">
            <body>
              <a href="/contact">Contact</a>
              <a href="/accessibilite">Accessibilité</a>
              <a href="/RGAA">Référentiel</a>
              <a href="/declaration">Déclaration d'accessibilité</a>
              <a href="/declaration-accessibilite">Accessibilité : non conforme</a>
            </body>
          </html>
        HTML
      end

      let(:expected_link_list) { %w[https://example.com/declaration-accessibilite https://example.com/declaration https://example.com/accessibilite https://example.com/RGAA] }

      it "prioritizes links correctly in the crawler" do
        allow(crawler).to receive(:find_page).and_return(nil)

        described_class.new(audit)

        expect(Crawler).to have_received(:new).with(root_url, root_page_html: home_page_html, queue: expected_link_list)
      end
    end

    context "when multiple accessibility pages exist" do
      let(:home_page_html) do
        <<-HTML
          <html lang="fr">
            <body>
              <a href="/accessibilite-et-inclusion">Accessibilité et inclusion</a>
              <a href="/accessibilite-et-voirie">Accessibilité et voirie</a>
              <a href="/accessibilite-conformite-partielle">Accessibilité - Conformité partielle</a>
            </body>
          </html>
        HTML
      end

      let(:expected_link_list) { %w[https://example.com/accessibilite-conformite-partielle https://example.com/accessibilite-et-inclusion https://example.com/accessibilite-et-voirie] }

      it "ranks the URLs matching the most terms first" do
        allow(crawler).to receive(:find_page).and_return(nil)

        described_class.new(audit)

        expect(Crawler).to have_received(:new).with(root_url, root_page_html: home_page_html, queue: expected_link_list)
      end
    end

    context "when a link has accented French text but an unrelated href" do
      let(:home_page_html) do
        <<-HTML
          <html lang="fr">
            <body>
              <a href="/mentions-legales">Voir notre déclaration</a>
              <a href="/random">Voir notre déclaration accessibilité</a>
              <a href="/contact">Contact</a>
            </body>
          </html>
        HTML
      end

      let(:expected_link_list) { %w[https://example.com/random https://example.com/mentions-legales] }

      it "includes the link based on its accented text" do
        allow(crawler).to receive(:find_page).and_return(nil)

        described_class.new(audit)

        expect(Crawler).to have_received(:new).with(root_url, root_page_html: home_page_html, queue: expected_link_list)
      end
    end

    context "when the homepage contains an external accessibility link" do
      let(:home_page_html) do
        "<a href=\"https://external.example.org/accessibilite\">Déclaration d'accessibilité</a>"
      end

      let(:expected_link_list) do
        ["https://external.example.org/accessibilite"]
      end

      it "adds the external link to the prioritized queue" do
        allow(crawler).to receive(:find_page).and_return(nil)

        described_class.new(audit)

        expect(Crawler).to have_received(:new).with(root_url, root_page_html: home_page_html, queue: expected_link_list)
      end
    end

    it "does nothing if no page is found" do
      allow(crawler).to receive(:find_page).and_return(nil)

      described_class.new(audit)

      expect(audit.reload.accessibility_page_url).to be_nil
      expect(audit.page_snapshots.where(kind: "accessibility")).to be_empty
    end
  end

  describe "#enqueue_children" do
    let(:service) { described_class.allocate }

    let(:audit) { create(:audit, :without_checks, site:, home_page_url: "https://www.example.com/redirection") }
    let(:queue) { [] }
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
      allow(page).to receive(:links).and_return(links)
      allow(service).to receive(:links_by_priority) { |incoming_links| incoming_links }
    end

    it "does not enqueues home, redirection and page url" do
      service.send(:enqueue_children, page, queue, audit)

      expect(queue).to eq(["https://example.com/a11y"])
    end
  end
end
