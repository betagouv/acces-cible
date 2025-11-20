require "rails_helper"

RSpec.describe Page do
  let(:root) { "https://éxample.com" }
  let(:url) { "https://éxample.com/about" }
  let(:normalized_url) { Link.normalize(url) }
  let(:page) { build(:page, url:, root:, html: body) }
  let(:content_type) { "text/html" }
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
    stub_request(:get, url).to_return(body:, headers: { "content-type": content_type })

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

  describe "#initialize" do
    let(:root) { nil }
    let(:page) { build(:page, url:, root:, html: "<html></html>") }

    context "when path is empty" do
      let(:url) { "https://example.com" }

      it "sets root to domain and slash" do
        expect(page.root).to eq("https://example.com/")
      end
    end

    context "when url contains a file" do
      let(:url) { "https://example.com/sitemap.xml" }

      it "sets root to everything up to the last slash" do
        expect(page.root).to eq("https://example.com/")
      end
    end

    context "when url contains a file in a nested path" do
      let(:url) { "https://example.com/path/to/file.pdf" }

      it "sets root to the file directory path" do
        expect(page.root).to eq("https://example.com/path/to/")
      end
    end

    context "when url is a page without extension" do
      let(:url) { "https://example.com/about" }

      it "sets root to the path" do
        expect(page.root).to eq("https://example.com/")
      end
    end

    context "when root is explicitly provided" do
      let(:url) { "https://example.com/path/to/file.pdf" }
      let(:root) { "https://example.com/path/" }

      it "uses the provided root" do
        expect(page.root).to eq(root)
      end
    end
  end

  describe "#path" do
    it "returns the path portion of the URL" do
      expect(page.path).to eq("about")
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
                          .and_return({ body:, status: 200, content_type:, current_url: normalized_url })
    end

    it "fetches the page content" do
      expect(page.html).to be_nil
    end

    context "when the response is not HTML" do
      let(:content_type) { "application/pdf" }

      it "raises InvalidTypeError" do
        expect { page }.to raise_error(Page::InvalidTypeError, /Not an HTML page.*application\/pdf/)
      end
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

    context "with between_headings: parameter" do
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

        result = page.text(between_headings: [/Start Section/, /End Section/])
        expect(result).to eq("This is the target content. Multiple paragraphs here. Item 1 Item 2")
      end

      context "when start heading is not found" do
        let(:body) { "<h1>End Section</h1>" }

        it "returns empty string" do
          result = page.text(between_headings: [/Nonexistent Start/, /End Section/])
          expect(result).to eq("")
        end
      end

      context "when end heading is not found" do
        let(:body) { "<h1>Start Section</h1>" }

        it "returns empty string" do
          result = page.text(between_headings: [/Start Section/, /Nonexistent End/])
          expect(result).to eq("")
        end
      end

      context "when both headings are not found" do
        let(:body) { "<h1>Some Heading</h1>" }

        it "returns empty string" do
          result = page.text(between_headings: [/Nonexistent Start/, /Nonexistent End/])
          expect(result).to eq("")
        end
      end

      context "when headings are adjacent with no content between" do
        let(:body) { "<h1>First</h1><h1>Second</h1>" }

        it "returns empty string" do
          result = page.text(between_headings: [/First/, /Second/])
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
          result = page.text(between_headings: [/Start/, /End/])
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
          result = page.text(between_headings: [/Start/, /End/])
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
          result = page.text(between_headings: [/H1 Start/, /H3 End/])
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
          result = page.text(between_headings: [/Section 1:/, /Section 2:/])
          expect(result).to eq("Target content")
        end

        it "uses partial pattern matching" do
          result = page.text(between_headings: [/Introduction/, /Conclusion/])
          expect(result).to eq("Target content")
        end
      end

      context "with string patterns" do
        let(:body) do
          <<~HTML
            <h1>Section 1: Introduction</h1>
            <p>Target content</p>
            <h1>Section 2: Conclusion</h1>
          HTML
        end

        it "uses StringComparison.match? for string matchers" do
          allow(StringComparison).to receive(:match?).and_call_original

          page.text(between_headings: ["Section 1", "Section 2"])

          expect(StringComparison).to have_received(:match?).with("Section 1", "Section 1: Introduction", ignore_case: true, fuzzy: 0.65)
          expect(StringComparison).to have_received(:match?).with("Section 2", "Section 2: Conclusion", ignore_case: true, fuzzy: 0.65)
        end

        it "matches headings with fuzzy case-insensitive matching" do
          result = page.text(between_headings: ["section 1 introduction", "section 2 conclusion"])
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
          result = page.text(between_headings: [/Start/, /End/])
          expect(result).to include("First section")
          expect(result).to include("Second section")
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
          result = page.text(between_headings: [/First Heading/, :next])
          expect(result).to eq("Content in first section")
        end

        it "works across different heading levels" do
          result = page.text(between_headings: [/Second Heading/, :next])
          expect(result).to eq("Content in second section")
        end

        context "when matched heading is the last heading" do
          it "returns empty string" do
            result = page.text(between_headings: [/Third Heading/, :next])
            expect(result).to eq("")
          end
        end

        context "when matched heading is not found" do
          it "returns empty string" do
            result = page.text(between_headings: [/Nonexistent/, :next])
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
          result = page.text(between_headings: [:previous, /Second Heading/])
          expect(result).to eq("Content in first section")
        end

        it "works across different heading levels" do
          result = page.text(between_headings: [:previous, /Third Heading/])
          expect(result).to eq("Content in second section")
        end

        context "when matched heading is the first heading" do
          it "returns empty string" do
            result = page.text(between_headings: [:previous, /First Heading/])
            expect(result).to eq("")
          end
        end

        context "when matched heading is not found" do
          it "returns empty string" do
            result = page.text(between_headings: [:previous, /Nonexistent/])
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
          result = page.text(between_headings: [:previous, :next])
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
          result = page.text(between_headings: [/Overview/, :next])
          expect(result).to include("Overview content with bold text")
          expect(result).to include("Item 1 Item 2")
          expect(result).not_to include("Details section")
        end

        it "extracts content from previous to heading" do
          result = page.text(between_headings: [:previous, /Details/])
          expect(result).to include("Overview content with bold text")
          expect(result).to include("Item 1 Item 2")
        end
      end
    end

    context "with scope: parameter" do
      it "extracts text within main content only" do
        page = build(:page, html: <<~HTML)
          <nav>
            <h1>Nav Start</h1>
            <p>Nav content</p>
            <h1>Nav End</h1>
          </nav>
          <main>
            <h1>Main Start</h1>
            <p>Main content</p>
            <h1>Main End</h1>
          </main>
        HTML

        result = page.text(scope: :main)
        expect(result).to include("Main content")
        expect(result).not_to include("Nav content")
      end

      it "falls back to full page when scope selector does not match" do
        page = build(:page, body: <<~HTML)
          <h1>Start</h1>
          <p>Content here</p>
          <h1>End</h1>
        HTML

        result = page.text(scope: :main)
        expect(result).to eq("Start Content here End")
      end
    end

    context "when combined with scope: and between_headings: parameters" do
      it "extracts text between headings within main content only" do
        page = build(:page, html: <<~HTML)
          <nav>
            <h1>Nav Start</h1>
            <p>Nav content</p>
            <h1>Nav End</h1>
          </nav>
          <main>
            <h1>Main Start</h1>
            <p>Main content</p>
            <h1>Main End</h1>
          </main>
        HTML

        result = page.text(scope: :main, between_headings: [/Main Start/, /Main End/])
        expect(result).to eq("Main content")
        expect(result).not_to include("Nav content")
      end

      it "searches for headings only within scoped content" do
        page = build(:page, html: <<~HTML)
          <nav>
            <h1>Start Section</h1>
            <p>Nav content</p>
            <h1>End Section</h1>
          </nav>
          <main>
            <h1>Other Heading</h1>
            <p>Main content</p>
          </main>
        HTML

        result = page.text(scope: :main, between_headings: [/Start Section/, /End Section/])
        expect(result).to eq("")
      end

      it "works with :next relative matcher within scope" do
        page = build(:page, html: <<~HTML)
          <nav>
            <h1>Nav Heading</h1>
            <p>Nav content</p>
          </nav>
          <main>
            <h1>Main First</h1>
            <p>Main content</p>
            <h2>Main Second</h2>
          </main>
        HTML

        result = page.text(scope: :main, between_headings: [/Main First/, :next])
        expect(result).to eq("Main content")
        expect(result).not_to include("Nav content")
      end

      it "works with :previous relative matcher within scope" do
        page = build(:page, html: <<~HTML)
          <nav>
            <h1>Nav Heading</h1>
            <p>Nav content</p>
          </nav>
          <main>
            <h1>Main First</h1>
            <p>Main content</p>
            <h2>Main Second</h2>
          </main>
        HTML

        result = page.text(scope: :main, between_headings: [:previous, /Main Second/])
        expect(result).to eq("Main content")
        expect(result).not_to include("Nav content")
      end
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
    end

    context "with between_headings: parameter" do
      it "returns links between two matching headings" do
        page = build(:page, body: <<~HTML)
          <h1>Start Section</h1>
          <a href="/link1">Link 1</a>
          <a href="/link2">Link 2</a>
          <h1>End Section</h1>
          <a href="/link3">Link 3</a>
        HTML

        links = page.links(between_headings: [/Start Section/, /End Section/])
        expect(links.collect(&:text)).to eq(["Link 1", "Link 2"])
        expect(links.collect(&:text)).not_to include("Link 3")
      end

      it "returns empty array when start heading is not found" do
        page = build(:page, body: "<h1>End Section</h1><a href='/link'>Link</a>")

        links = page.links(between_headings: [/Nonexistent Start/, /End Section/])
        expect(links).to eq([])
      end

      it "returns empty array when end heading is not found" do
        page = build(:page, body: "<h1>Start Section</h1><a href='/link'>Link</a>")

        links = page.links(between_headings: [/Start Section/, /Nonexistent End/])
        expect(links).to eq([])
      end

      it "returns empty array when headings are adjacent with no links between" do
        page = build(:page, body: "<h1>First</h1><h2>Second</h2><a href='/link'>Link</a>")

        links = page.links(between_headings: [/First/, /Second/])
        expect(links).to eq([])
      end

      context "with :next relative matcher" do
        it "returns links from matched heading to next heading" do
          page = build(:page, body: <<~HTML)
            <h1>First Heading</h1>
            <a href="/link1">Link 1</a>
            <h2>Second Heading</h2>
            <a href="/link2">Link 2</a>
          HTML

          links = page.links(between_headings: [/First Heading/, :next])
          expect(links.collect(&:text)).to eq(["Link 1"])
          expect(links.collect(&:text)).not_to include("Link 2")
        end

        it "returns empty array when matched heading is the last heading" do
          page = build(:page, body: "<h1>Last Heading</h1><a href='/link'>Link</a>")

          links = page.links(between_headings: [/Last Heading/, :next])
          expect(links).to eq([])
        end
      end

      context "with :previous relative matcher" do
        it "returns links from previous heading to matched heading" do
          page = build(:page, body: <<~HTML)
            <h1>First Heading</h1>
            <a href="/link1">Link 1</a>
            <h2>Second Heading</h2>
            <a href="/link2">Link 2</a>
          HTML

          links = page.links(between_headings: [:previous, /Second Heading/])
          expect(links.collect(&:text)).to eq(["Link 1"])
          expect(links.collect(&:text)).not_to include("Link 2")
        end

        it "returns empty array when matched heading is the first heading" do
          page = build(:page, body: "<h1>First Heading</h1><a href='/link'>Link</a>")

          links = page.links(between_headings: [:previous, /First Heading/])
          expect(links).to eq([])
        end
      end

      context "when combined with scope: :main" do
        it "applies scope first, then between" do
          page = build(:page, html: <<~HTML)
            <nav>
              <h1>Nav Heading</h1>
              <a href="/nav-link">Nav Link</a>
              <h1>Nav End</h1>
            </nav>
            <main>
              <h1>Main Start</h1>
              <a href="/main-link1">Main Link 1</a>
              <h1>Main End</h1>
              <a href="/main-link2">Main Link 2</a>
            </main>
          HTML

          links = page.links(scope: :main, between_headings: [/Main Start/, /Main End/])
          expect(links.collect(&:text)).to eq(["Main Link 1"])
          expect(links.collect(&:text)).not_to include("Nav Link", "Main Link 2")
        end

        it "searches for headings only within scoped content" do
          page = build(:page, html: <<~HTML)
            <nav>
              <h1>Start Section</h1>
              <a href="/nav-link">Nav Link</a>
              <h1>End Section</h1>
            </nav>
            <main>
              <h1>Other Heading</h1>
              <a href="/main-link">Main Link</a>
            </main>
          HTML

          links = page.links(scope: :main, between_headings: [/Start Section/, /End Section/])
          expect(links).to eq([])
        end
      end

      context "when combined with skip_files: false" do
        it "includes file links between headings" do
          page = build(:page, body: <<~HTML)
            <h1>Start</h1>
            <a href="/document.pdf">PDF Document</a>
            <a href="/page">Regular Link</a>
            <h1>End</h1>
          HTML

          links = page.links(between_headings: [/Start/, /End/], skip_files: false)
          expect(links.collect(&:text)).to eq(["PDF Document", "Regular Link"])
        end
      end

      context "with string patterns" do
        it "uses StringComparison.match? for string matchers" do
          page = build(:page, body: <<~HTML)
            <h1>Start Section</h1>
            <a href="/link1">Link 1</a>
            <h1>End Section</h1>
          HTML

          allow(StringComparison).to receive(:match?).and_call_original

          page.links(between_headings: ["Start", "End"])

          expect(StringComparison).to have_received(:match?).with("Start", "Start Section", ignore_case: true, fuzzy: 0.65)
          expect(StringComparison).to have_received(:match?).with("End", "End Section", ignore_case: true, fuzzy: 0.65)
        end

        it "matches headings with fuzzy case-insensitive matching" do
          page = build(:page, body: <<~HTML)
            <h1>Start Section</h1>
            <a href="/link1">Link 1</a>
            <a href="/link2">Link 2</a>
            <h1>End Section</h1>
          HTML

          links = page.links(between_headings: ["start section", "end section"])
          expect(links.collect(&:text)).to eq(["Link 1", "Link 2"])
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
end
