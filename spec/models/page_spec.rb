require "rails_helper"

RSpec.describe Page do
  let(:root) { "https://example.com" }
  let(:url) { "https://example.com/about" }
  let(:parsed_url) { URI.parse(url) }
  let(:page) { described_class.new(url:, root:) }
  let(:html_content) do
    <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <title>Example Page</title>
        </head>
        <body>
          <h1>Main Heading</h1>
          <h2>Sub Heading</h2>
          <p>Some content</p>
          <a href="/contact">Contact</a>
          <a href="https://external.com">External</a>
          <a href="tel:123456">Phone</a>
          <a href="mailto:test@example.com">Email</a>
          <a href="#section">Section</a>
          <a href="relative/path">Relative</a>
        </body>
      </html>
    HTML
  end

  before do
    allow(Net::HTTP).to receive(:get).and_return(html_content)
  end

  describe "#path" do
    it "returns the path portion of the URL" do
      expect(page.path).to eq("/about")
    end

    context "when URL is the root URL" do
      let(:url) { root }

      it "returns an empty string" do
        expect(page.path).to eq("")
      end
    end
  end

  describe "#root?" do
    it "returns false when URL is not the root URL" do
      expect(page.root?).to be false
    end

    context "when URL is the root URL" do
      let(:url) { root }

      it "returns true" do
        expect(page.root?).to be true
      end
    end
  end

  describe "#html" do
    it "fetches and caches the page content" do
      expect(Rails.cache).to receive(:fetch)
        .with(parsed_url, expires_in: described_class::CACHE_TTL)
        .and_yield

      expect(page.html).to eq(html_content)
      expect(Net::HTTP).to have_received(:get)
        .with(Addressable::URI.parse(url))
        .once
    end
  end

  describe "#dom" do
    it "returns a Nokogiri::HTML document" do
      expect(page.dom).to be_a(Nokogiri::HTML::Document)
    end
  end

  describe "#css" do
    it "forwards CSS selector queries to the DOM" do
      expect(page.css("h1").first.text).to eq("Main Heading")
    end
  end

  describe "#title" do
    it "returns the page title" do
      expect(page.title).to eq("Example Page")
    end
  end

  describe "#text" do
    it "returns the full text content" do
      expect(page.text).to include("Main Heading", "Sub Heading", "Some content")
    end
  end

  describe "#headings" do
    it "returns an array of text, one line for each heading" do
      expect(page.headings).to eq(["Main Heading", "Sub Heading"])
    end
  end

  describe "#links" do
    it "returns a hash of URLs and their link texts" do
      expected_links = [
        Link.new("https://example.com/contact", "Contact"),
        Link.new("https://external.com", "External"),
        Link.new("https://example.com/relative/path", "Relative"),
      ]
      expect(page.links).to eq(expected_links)
    end

    it "excludes mailto and tel links" do
      expect(page.links.collect(&:text)).not_to include("Phone", "Email")
    end

    it "excludes fragment-only links" do
      expect(page.links.collect(&:text)).not_to include("Section")
    end

    it "resolves relative URLs" do
      expect(page.links.collect(&:href)).to include("https://example.com/relative/path")
    end

    it "strips fragments and query parameters from URLs" do
      html_with_params = html_content.gsub(
        '<a href="https://external.com">',
        '<a href="https://external.com?param=1#section">'
      )
      allow(Net::HTTP).to receive(:get).and_return(html_with_params)

      expect(page.links.collect(&:href)).to include("https://external.com")
    end
  end

  describe "#internal_links" do
    it "returns only links that start with the root URL" do
      expected_internal_links = [
        Link.new("https://example.com/contact", "Contact"),
        Link.new("https://example.com/relative/path", "Relative"),
      ]
      expect(page.internal_links).to eq(expected_internal_links)
    end
  end

  describe "#external_links" do
    it "returns only links that don't start with the root URL" do
      expected_external_links = [
        Link.new("https://external.com", "External")
      ]
      expect(page.external_links).to eq(expected_external_links)
    end
  end
end
