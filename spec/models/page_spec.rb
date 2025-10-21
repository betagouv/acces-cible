require "rails_helper"

RSpec.describe Page do
  let(:root) { "https://éxample.com" }
  let(:url) { "https://éxample.com/about" }
  let(:normalized_url) { Link.normalize(url) }
  let(:page) { build(:page, url:, root:, html: body) }
  let(:headers) { { "Content-Type" => "text/html" } }
  let(:body) do
    <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <title>Example Page</title>
          <style>/* CSS comment */</style>
          <meta name="viewport" content="user-scalable=no">
        </head>
        <body>
          <h1>Main Heading</h1>
          <h2>Sub Heading</h2>
          <p>Some content</p>
          <p>Text<strong>without</strong>spaces<em>between</em><code>tags</code></p>
          <a href="/contact">Contact</a>
          <a href="https://external.com">External</a>
          <a href="tel:123456">Phone</a>
          <a href="mailto:test@example.com">Email</a>
          <a href="#section">Section</a>
          <a href="relative/path">Relative</a>
          <a href="javascript:alert('')">Javascript</a>
          <a href="void(location.href='')">Void</a>
          <a href="document.pdf">PDF</a>
          <a href="file.zip">ZIP</a>
          <a href="report.docx">DOCX</a>
          <a href="image.jpg">JPG</a>
          <a href="webcal.ical">ICAL</a>
          <a href="rss.atom">ATOM</a>
          <a href="holidays.mov">MOV</a>
          <div class="d-none" style="display: none;">display: none;</div>
        </body>
      </html>
    HTML
  end

  before do
    stub_request(:get, url).to_return(body:, headers:)

    # Mock Browser to prevent real Ferrum::Browser instantiation
    ferrum_browser = instance_double(Ferrum::Browser)
    network = instance_double(Ferrum::Network)
    allow(Ferrum::Browser).to receive(:new).and_return(ferrum_browser)
    allow(ferrum_browser).to receive(:network).and_return(network)
    allow(network).to receive(:blocklist=)
    allow(ferrum_browser).to receive(:reset)
    allow(ferrum_browser).to receive(:close)
    allow(ferrum_browser).to receive(:quit)
  end

  describe "#path" do
    it "returns the path portion of the URL" do
      expect(page.path).to eq("about/")
    end

    context "when URL is the root URL" do
      let(:url) { root }

      it "returns empty string" do
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
        allow(page).to receive(:actual_url).and_return(Link.normalize(url))

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
        .with(normalized_url)
        .and_return({ body:, status: 200, headers:, current_url: normalized_url })
    end

    it "fetches the page content" do
      expect(page.html).to be_nil
    end

    it "attempts to use the cache" do
      allow(Rails.cache).to receive(:fetch)
        .with(normalized_url, expires_in: described_class::CACHE_TTL)

      page
      expect(Rails.cache).to have_received(:fetch)
        .with(normalized_url, expires_in: described_class::CACHE_TTL)
    end

    context "when the response is not HTML" do
      let(:headers) { { "Content-Type" => "application/pdf" } }

      it "raises InvalidTypeError" do
        expect { page }.to raise_error(Page::InvalidTypeError, /Not an HTML page.*application\/pdf/)
      end
    end
  end

  describe "#refresh" do
    let(:body) { nil }
    let(:new_body) { "<html><body><h1>Refreshed Content</h1></body></html>" }

    before do
      allow(Browser).to receive(:get)
        .with(normalized_url)
        .and_return({ body: new_body, status: 200, headers:, current_url: normalized_url })
    end

    it "clears the cache and calls Browser.get" do
      expect(Rails.cache).to receive(:clear).with(normalized_url)
      expect(Browser).to receive(:get).with(normalized_url)
      page.refresh
    end

    it "returns self for method chaining" do
      expect(page.refresh).to eq(page)
    end
  end

  describe "#dom" do
    it "returns a Nokogiri::HTML document" do
      expect(page.dom).to be_a(Nokogiri::HTML::Document)
    end

    it "ignores invisible elements" do
      expect(page.dom.css("style, meta, div.d-none")).to be_empty
    end

    it "caches the parsed document" do
      first_dom = page.dom
      second_dom = page.dom
      expect(first_dom).to be(second_dom)
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
      expect(page.css("h1").first.text.squish).to eq("Main Heading")
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
      expect(page.text).to include("Text without spaces between tags")
      expect(page.text).not_to include("CSS comment")
    end
  end

  describe "#heading_levels" do
    it "returns an array of heading and level arrays" do
      expect(page.heading_levels).to eq([[1, "Main Heading"], [2, "Sub Heading"]])
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
        Link.new("https://éxample.com/contact", "Contact"),
        Link.new("https://external.com/", "External"),
        Link.new("https://éxample.com/relative/path", "Relative"),
      ]
      expect(page.links).to eq(expected_links)
    end

    it "excludes mailto and tel links" do
      expect(page.links.collect(&:text)).not_to include("Phone", "Email")
    end

    it "excludes fragment-only links" do
      expect(page.links.collect(&:text)).not_to include("Section")
    end

    context "with fragment URLs" do
      let(:body) do
        <<~HTML
          <a href="https://external.com/">Link 1</a>
          <a href="https://external.com/#section">Link 2</a>
        HTML
      end

      it "strips fragments from URLs but keeps duplicate links" do
        expect(page.links.collect(&:href)).to eq(["https://external.com/", "https://external.com/"])
      end
    end

    context "with skip_files: true (default)" do
      it "excludes links to non-HTML files" do
        expect(page.links.collect(&:text)).not_to include("PDF", "ZIP", "JPG")
      end
    end

    context "with skip_files: false" do
      it "excludes ical, atom, movies, etc" do
        expect(page.links(skip_files: false).collect(&:text)).not_to include("ICAL", "ATOM", "MOV")
      end

      it "includes file links" do
        expect(page.links(skip_files: false).collect(&:text)).to include("PDF", "ZIP", "DOCX")
      end
    end

    context "with scope: :main" do
      it "returns only links within the main content area" do
        page = build(:page, html: <<~HTML)
          <nav><a href="/nav-link">Navigation Link</a></nav>
          <main><a href="/main-link">Main Link</a><a href="/another-main-link">Another Main Link</a></main>
          <footer><a href="/footer-link">Footer Link</a></footer>
        HTML

        links = page.links(scope: :main)
        expect(links.collect(&:text)).to eq(["Main Link", "Another Main Link"])
        expect(links.collect(&:text)).not_to include("Navigation Link", "Footer Link")
      end

      context "when main tag is not present" do
        it "falls back to [role=main] selector" do
          page = build(:page, html: <<~HTML)
            <nav><a href="/nav-link">Navigation Link</a></nav>
            <div role="main"><a href="/main-link">Main Link</a></div>
            <footer><a href="/footer-link">Footer Link</a></footer>
          HTML

          links = page.links(scope: :main)
          expect(links.collect(&:text)).to eq(["Main Link"])
          expect(links.collect(&:text)).not_to include("Navigation Link", "Footer Link")
        end
      end

      context "when no main content selector matches" do
        it "returns all links from the page" do
          page = build(:page, links: ["/link1/", "/link2/"])

          links = page.links(scope: :main)
          expect(links.collect(&:href)).to include("https://www.example.com/link1/", "https://www.example.com/link2/")
        end
      end

      context "when multiple main content elements exist" do
        it "uses only the first matching element" do
          page = build(:page, html: "<main><a href='/first-main-link'>First Main Link</a></main><div class='content'><a href='/content-link'>Content Link</a></div>")

          links = page.links(scope: :main)
          expect(links.collect(&:text)).to eq(["First Main Link"])
          expect(links.collect(&:text)).not_to include("Content Link")
        end
      end

      context "when invalid scope is provided" do
        it "falls back to full page" do
          page = build(:page, links: ["/link1/", "/link2/"])

          links = page.links(scope: :invalid_scope)
          expect(links.collect(&:href)).to include("https://www.example.com/link1/", "https://www.example.com/link2/")
        end
      end

      context "with factory wrap_in parameter" do
        it "wraps links in specified tag when using string" do
          page = build(:page,
            links: [["/main-link", "Main Link"], ["/other-link", "Other Link"]],
            wrap_in: "main")

          main_links = page.links(scope: :main)
          expect(main_links.collect(&:text)).to eq(["Main Link", "Other Link"])

          expect(page.links).to eq(main_links)
        end

        it "wraps links in specified tags when using array" do
          page = build(:page,
            links: [["/content-link", "Content Link"]],
            wrap_in: ['<div role="main">', "</div>"])

          scoped_links = page.links(scope: :main)
          expect(scoped_links.collect(&:text)).to eq(["Content Link"])
        end

        it "wraps all content (headings, links, body) in specified tag" do
          page = build(:page,
            headings: ["Main Heading"],
            links: [["/link1", "Link 1"]],
            body: "<p>Body content</p>",
            wrap_in: "main")

          expect(page.css("main h1").text.squish).to eq("Main Heading")
          expect(page.css("main a").first.text.squish).to eq("Link 1")
          expect(page.css("main p").text.squish).to include("Body content")

          scoped_links = page.links(scope: :main)
          expect(scoped_links.collect(&:text)).to eq(["Link 1"])
        end

        it "wraps body content inside main when using wrap_in" do
          page = build(:page,
            links: [["/main-link", "Main Link"]],
            body: "<div><a href='/body-link'>Body Link</a></div>",
            wrap_in: "main")

          main_links = page.links(scope: :main)
          expect(main_links.collect(&:text)).to include("Main Link", "Body Link")

          expect(page.css("main a").length).to eq(2)
        end

        it "keeps content outside main when not using factory attributes" do
          page = build(:page,
            links: [["/main-link", "Main Link"]],
            wrap_in: "main",
            html: <<~HTML)
              <html>
                <body>
                  <main><a href="/main-link">Main Link</a></main>
                  <footer><a href="/footer-link">Footer Link</a></footer>
                </body>
              </html>
            HTML

          main_links = page.links(scope: :main)
          expect(main_links.collect(&:text)).to eq(["Main Link"])
          expect(main_links.collect(&:text)).not_to include("Footer Link")

          all_links = page.links
          expect(all_links.collect(&:text)).to include("Main Link", "Footer Link")
        end
      end
    end
  end

  describe "#internal_links" do
    it "returns only links that start with the root URL" do
      expected_internal_links = [
        Link.new("https://éxample.com/contact", "Contact"),
        Link.new("https://éxample.com/relative/path", "Relative"),
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

  describe "#text_between_headings" do
    let(:page) { build(:page, body:) }
    let(:body) { "" }

    it "returns text between two matching headings" do
      page = build(:page, body: <<~HTML)
        <h1>Start Section</h1>
        <p>This is the target content.</p>
        <p>Multiple paragraphs here.</p>
        <ul>
          <li>Item 1</li>
          <li>Item 2</li>
        </ul>
        <h1>End Section</h1>
      HTML

      result = page.text_between_headings(/Start Section/, /End Section/)
      expect(result).to eq("This is the target content. Multiple paragraphs here. Item 1 Item 2")
    end

    context "when start heading is not found" do
      let(:body) { "<h1>End Section</h1>" }

      it "returns empty string" do
        result = page.text_between_headings(/Nonexistent Start/, /End Section/)
        expect(result).to eq("")
      end
    end

    context "when end heading is not found" do
      let(:body) { "<h1>Start Section</h1>" }

      it "returns empty string" do
        result = page.text_between_headings(/Start Section/, /Nonexistent End/)
        expect(result).to eq("")
      end
    end

    context "when both headings are not found" do
      let(:body) { "<h1>Some Heading</h1>" }

      it "returns empty string" do
        result = page.text_between_headings(/Nonexistent Start/, /Nonexistent End/)
        expect(result).to eq("")
      end
    end

    context "when headings are adjacent with no content between" do
      let(:body) { "<h1>First</h1><h1>Second</h1>" }

      it "returns empty string" do
        result = page.text_between_headings(/First/, /Second/)
        expect(result).to eq("")
      end
    end

    context "with nested elements between headings" do
      let(:body) do
        <<~HTML
          <h1>Start Section</h1>
          <div>
            <p>Nested <strong>bold</strong> and <em>italic</em> text</p>
            <div><span>Deeply nested content</span></div>
          </div>
          <h1>End Section</h1>
        HTML
      end

      it "extracts all text from nested elements" do
        result = page.text_between_headings(/Start/, /End/)
        expect(result).to include("Nested bold and italic text")
        expect(result).to include("Deeply nested content")
      end
    end

    context "with invisible elements between headings" do
      let(:body) do
        <<~HTML
          <h1>Start Section</h1>
          <p>Visible content</p>
          <div style="display: none;">Hidden content</div>
          <script>console.log('script')</script>
          <h1>End Section</h1>
        HTML
      end

      it "excludes invisible elements from result" do
        result = page.text_between_headings(/Start/, /End/)
        expect(result).to eq("Visible content")
        expect(result).not_to include("Hidden content")
        expect(result).not_to include("script")
      end
    end

    context "with different heading levels" do
      let(:body) do
        <<~HTML
          <h1>H1 Start</h1>
          <p>Content between h1 and h3</p>
          <h3>H3 End</h3>
        HTML
      end

      it "works across different heading levels" do
        result = page.text_between_headings(/H1 Start/, /H3 End/)
        expect(result).to eq("Content between h1 and h3")
      end
    end

    context "with regex patterns" do
      let(:body) do
        <<~HTML
          <h1>Section 1: Introduction</h1>
          <p>Target content</p>
          <h1>Section 2: Conclusion</h1>
        HTML
      end

      it "matches headings using regex patterns" do
        result = page.text_between_headings(/Section 1:/, /Section 2:/)
        expect(result).to eq("Target content")
      end

      it "uses partial pattern matching" do
        result = page.text_between_headings(/Introduction/, /Conclusion/)
        expect(result).to eq("Target content")
      end
    end

    context "when multiple headings match the pattern" do
      let(:body) do
        <<~HTML
          <h1>Start</h1>
          <p>First section</p>
          <h1>Start</h1>
          <p>Second section</p>
          <h1>End</h1>
        HTML
      end

      it "uses the first matching heading" do
        result = page.text_between_headings(/Start/, /End/)
        expect(result).to include("First section")
        expect(result).to include("Second section")
      end
    end

    context "with custom matcher responding to match?" do
      let(:simple_matcher_class) do
        Class.new do
          def initialize(expected)
            @expected = expected
          end

          def match?(text)
            text == @expected
          end
        end
      end

      it "works with custom matchers" do
        page = build(:page, body: <<~HTML)
          <h1>Start Section</h1>
          <p>Content here</p>
          <h1>End Section</h1>
        HTML

        matcher = simple_matcher_class.new("Start Section")
        result = page.text_between_headings(matcher, /End/)
        expect(result).to eq("Content here")
      end
    end

    context "with :next relative matcher" do
      let(:body) do
        <<~HTML
          <h1>First Heading</h1>
          <p>Content in first section</p>
          <h2>Second Heading</h2>
          <p>Content in second section</p>
          <h3>Third Heading</h3>
        HTML
      end

      it "returns text from matched heading to next heading" do
        result = page.text_between_headings(/First Heading/, :next)
        expect(result).to eq("Content in first section")
      end

      it "works across different heading levels" do
        result = page.text_between_headings(/Second Heading/, :next)
        expect(result).to eq("Content in second section")
      end

      context "when matched heading is the last heading" do
        it "returns empty string" do
          result = page.text_between_headings(/Third Heading/, :next)
          expect(result).to eq("")
        end
      end

      context "when matched heading is not found" do
        it "returns empty string" do
          result = page.text_between_headings(/Nonexistent/, :next)
          expect(result).to eq("")
        end
      end
    end

    context "with :previous relative matcher" do
      let(:body) do
        <<~HTML
          <h1>First Heading</h1>
          <p>Content in first section</p>
          <h2>Second Heading</h2>
          <p>Content in second section</p>
          <h3>Third Heading</h3>
        HTML
      end

      it "returns text from previous heading to matched heading" do
        result = page.text_between_headings(:previous, /Second Heading/)
        expect(result).to eq("Content in first section")
      end

      it "works across different heading levels" do
        result = page.text_between_headings(:previous, /Third Heading/)
        expect(result).to eq("Content in second section")
      end

      context "when matched heading is the first heading" do
        it "returns empty string" do
          result = page.text_between_headings(:previous, /First Heading/)
          expect(result).to eq("")
        end
      end

      context "when matched heading is not found" do
        it "returns empty string" do
          result = page.text_between_headings(:previous, /Nonexistent/)
          expect(result).to eq("")
        end
      end
    end

    context "with both :next and :previous matchers" do
      let(:body) do
        <<~HTML
          <h1>First</h1>
          <h2>Second</h2>
        HTML
      end

      it "returns empty string as there is no anchor heading" do
        result = page.text_between_headings(:previous, :next)
        expect(result).to eq("")
      end
    end

    context "with relative matchers on complex page structure" do
      let(:body) do
        <<~HTML
          <h1>Introduction</h1>
          <p>Introduction text</p>
          <h2>Overview</h2>
          <p>Overview content with <strong>bold text</strong></p>
          <ul>
            <li>Item 1</li>
            <li>Item 2</li>
          </ul>
          <h2>Details</h2>
          <p>Details section</p>
          <h1>Conclusion</h1>
        HTML
      end

      it "extracts content between heading and next with nested elements" do
        result = page.text_between_headings(/Overview/, :next)
        expect(result).to include("Overview content with bold text")
        expect(result).to include("Item 1 Item 2")
        expect(result).not_to include("Details section")
      end

      it "extracts content from previous to heading" do
        result = page.text_between_headings(:previous, /Details/)
        expect(result).to include("Overview content with bold text")
        expect(result).to include("Item 1 Item 2")
      end
    end
  end
end
