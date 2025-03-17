require "rails_helper"

RSpec.describe Page do
  let(:root) { "https://example.com" }
  let(:url) { "https://example.com/about" }
  let(:parsed_url) { URI.parse(url) }
  let(:page) { build(:page, url: url, root: root, html: body) }
  let(:headers) { { "Content-Type" => "text/html" } }
  let(:body) do
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
    stub_request(:get, url).to_return(body:, headers:)
  end

  describe "#path" do
    it "returns the path portion of the URL" do
      expect(page.path).to eq("about")
    end

    context "when URL is the root URL" do
      let(:url) { root }

      it "returns a slash" do
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

  describe "#redirected?" do
    context "when actual_url is the original URL" do
      it "returns false" do
        allow(page).to receive(:actual_url).and_return(parsed_url)

        expect(page.redirected?).to be false
      end
    end

    context "when actual_url is different from the original URL" do
      it "returns true" do
        allow(page).to receive(:actual_url).and_return(root)

        expect(page.redirected?).to be true
      end
    end
  end

  describe "#fetch" do
    let(:body) { nil }

    before do
      allow(Browser).to receive(:get)
        .with(url)
        .and_return({ body:, status: 200, headers:, current_url: parsed_url })
    end

    it "fetches the page content" do
      expect(page.html).to be_nil
    end

    it "attempts to use the cache" do
      allow(Rails.cache).to receive(:fetch)
        .with(parsed_url, expires_in: described_class::CACHE_TTL)

      page
      expect(Rails.cache).to have_received(:fetch)
        .with(parsed_url, expires_in: described_class::CACHE_TTL)
    end

    context "when the response is not HTML" do
      let(:headers) { { "Content-Type" => "application/pdf" } }

      it "raises InvalidTypeError" do
        expect { page }.to raise_error(Page::InvalidTypeError, /Not an HTML page.*application\/pdf/)
      end
    end
  end

  describe "#dom" do
    it "returns a Nokogiri::HTML document" do
      expect(page.dom).to be_a(Nokogiri::HTML::Document)
    end

    context "when HTML is invalid" do
      let(:nokogiri_document) { instance_double(Nokogiri::HTML::Document) }

      it "raises ParseError" do
        allow(Nokogiri).to receive(:HTML).with(body).and_raise(Nokogiri::SyntaxError)
        expect { page.dom }.to raise_error(Page::ParseError, /Failed to parse HTML/)
      end
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
    it "returns an array of links" do
      expected_links = [
        Link.new("https://example.com/contact", "Contact"),
        Link.new("https://external.com/", "External"),
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

    context "with links to non-HTML files" do
      let(:body) do
        <<~HTML
          <a href="document.pdf">PDF</a>
          <a href="file.zip">ZIP</a>
          <a href="image.jpg">JPG</a>
        HTML
      end

      it "excludes links to non-HTML files" do
        expect(page.links.collect(&:text)).not_to include("PDF", "ZIP", "JPG")
      end
    end

    context "with fragment URLs" do
      let(:body) do
        <<~HTML
          <a href="https://external.com/">Link 1</a>
          <a href="https://external.com/#section">Link 2</a>
        HTML
      end

      it "strips fragments from URLs" do
        expect(page.links.collect(&:href)).to contain_exactly("https://external.com/")
      end
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
