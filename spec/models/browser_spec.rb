require "rails_helper"

RSpec.describe Browser do
  let(:url) { "https://example.com/" }
  let(:network_double) { instance_double(Ferrum::Network, status: 200, response: nil) }
  let(:browser_double) { instance_double(Ferrum::Browser) }
  let(:headers_double) { instance_double(Ferrum::Headers) }
  let(:page_double) { instance_double(Ferrum::Page) }
  let(:response_double) { instance_double(Ferrum::Network::Response) }

  before do
    allow(described_class).to receive(:browser).and_return(browser_double)
    allow(browser_double).to receive(:create_page).and_return(page_double)
    allow(browser_double).to receive(:quit)

    allow(headers_double).to receive(:set)
    allow(network_double).to receive(:blacklist=)
    allow(network_double).to receive(:wait_for_idle)
    allow(network_double).to receive_messages(status: 200, response: response_double)
    allow(response_double).to receive(:content_type).and_return("text/html")

    allow(page_double).to receive(:at_css)
    allow(page_double).to receive(:go_to).with(url)
    allow(page_double).to receive_messages(headers: headers_double, network: network_double, body: "<html><body>Test</body></html>", current_url: url)
    allow(page_double).to receive(:close)

    allow(Link).to receive(:normalize).with(url).and_return(url)
  end

  describe ".reachable?" do
    subject(:reachable?) { described_class.reachable?(url) }

    before do
      allow(described_class).to receive(:head).and_return(head_response)
    end

    context "when URL is nil" do
      let(:url) { nil }
      let(:head_response) { { status: 200 } }

      it "returns false" do
        expect(reachable?).to be_falsey
      end

      it "does not make a HEAD request" do
        reachable?
        expect(described_class).not_to have_received(:head)
      end
    end

    context "when URL is present and HEAD returns 200" do
      let(:head_response) { { status: 200 } }

      it "returns true" do
        expect(reachable?).to be(true)
      end

      it "makes a HEAD request with the URL" do
        reachable?
        expect(described_class).to have_received(:head).with(url)
      end
    end

    [0, 404, 500].each do |status|
      context "when URL is present but HEAD returns #{status}" do
        let(:head_response) { { status: } }

        it "returns false" do
          expect(reachable?).to be(false)
        end
      end
    end
  end

  describe ".head" do
    subject(:head_result) { described_class.head(url) }

    let(:response) { instance_double(HTTP::Response) }
    let(:uri) { instance_double(Addressable::URI) }
    let(:http_chain) { instance_double(HTTP::Client) }
    let(:ssl) { { verify_mode: OpenSSL::SSL::VERIFY_NONE } }

    before do
      allow(HTTP).to receive(:headers).and_return(http_chain)
      allow(http_chain).to receive_messages(timeout: http_chain, follow: http_chain)
      allow(http_chain).to receive(:head).with(url, ssl:).and_return(response)
      allow(response).to receive(:uri).and_return(uri)
      allow(uri).to receive(:to_s).and_return(url)
      allow(Link).to receive(:normalize).and_return(url)
    end

    context "when request is successful" do
      before do
        allow(response).to receive(:code).and_return(200)
      end

      it "makes HEAD request with correct options" do
        head_result

        expect(HTTP).to have_received(:headers)
        expect(http_chain).to have_received(:timeout).with(connect: 3, read: 3)
        expect(http_chain).to have_received(:follow).with(max_hops: 3)
        expect(http_chain).to have_received(:head).with(url, ssl:)
      end

      it "returns hash with status and normalized current_url" do
        expect(head_result).to be_a(Hash)
        expect(head_result.keys).to contain_exactly(:status, :current_url)
        expect(head_result[:status]).to eq(200)
        expect(head_result[:current_url]).to eq(url)
        expect(Link).to have_received(:normalize).with(url)
      end
    end

    # rubocop:disable RSpec/MultipleMemoizedHelpers
    context "when request follows redirects" do
      let(:final_url) { "https://example.com/final" }
      let(:normalized_url) { "https://example.com/final/" }

      before do
        allow(response).to receive(:code).and_return(200)
        allow(uri).to receive(:to_s).and_return(final_url)
        allow(Link).to receive(:normalize).with(final_url).and_return(normalized_url)
      end

      it "returns normalized effective URL" do
        expect(head_result[:current_url]).to eq(normalized_url)
        expect(Link).to have_received(:normalize).with(final_url)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    context "when request times out" do
      before do
        allow(http_chain).to receive(:head).with(url, ssl:).and_raise(HTTP::Error)
      end

      it "returns status 0" do
        expect(head_result[:status]).to eq(0)
      end

      it "returns normalized original URL when request fails" do
        expect(head_result[:current_url]).to eq(url)
        expect(Link).to have_received(:normalize).with(url)
      end
    end

    context "when response code is nil" do
      before do
        allow(response).to receive(:code).and_return(nil)
      end

      it "returns status 0" do
        expect(head_result[:status]).to eq(0)
      end
    end

    [404, 500, 301, 302].each do |code|
      context "when response code is #{code}" do
        before do
          allow(response).to receive(:code).and_return(code)
        end

        it "returns correct status code" do
          expect(head_result[:status]).to eq(code)
        end
      end
    end
  end

  describe ".get" do
    subject(:get_result) { described_class.get(url) }

    it "creates a new browser instance and calls get" do
      expect(get_result).not_to be_nil
    end

    it "waits for network idle" do
      get_result

      expect(network_double).to have_received(:wait_for_idle).with(timeout: Browser::PAGE_TIMEOUT)
    end

    it "returns response data hash" do
      result = get_result

      expect(result).to be_a(Hash)
      expect(result).to have_key(:body)
      expect(result).to have_key(:status)
      expect(result).to have_key(:content_type)
      expect(result).to have_key(:current_url)
    end

    it "returns correct response body" do
      expect(get_result[:body]).to eq("<html><body>Test</body></html>")
    end

    it "returns correct status code" do
      expect(get_result[:status]).to eq(200)
    end

    it "returns normalized current URL" do
      expect(get_result[:current_url]).to eq(url)
    end
  end

  describe "#browser" do
    it "creates a new Ferrum::Browser instance during initialization" do
      expect(described_class.send(:browser)).to eq(browser_double)
    end
  end

  describe "#with_page" do
    it "yields the created page" do
      expect { |block| described_class.send(:with_page, &block) }.to yield_with_args(page_double)
    end

    it "closes the page after yielding" do
      described_class.send(:with_page) { |p| "result" }
      expect(page_double).to have_received(:close)
    end

    it "returns the result of the yielded block" do
      result = described_class.send(:with_page) { |p| "test_result" }
      expect(result).to eq("test_result")
    end
  end

  describe "#create_page" do
    before do
      allow(browser_double).to receive(:create_page).and_return(page_double)
      allow(headers_double).to receive(:set)
      allow(page_double).to receive(:headers).and_return(headers_double)
    end

    it "creates a page from the browser" do
      result = described_class.send(:create_page)

      expect(browser_double).to have_received(:create_page)
      expect(result).to eq(page_double)
    end

    it "sets the blacklist on the page's context" do
      expect(network_double)
        .to receive(:blacklist=)
              .with([described_class::BLOCKED_EXTENSIONS, described_class::BLOCKED_DOMAINS])

      described_class.send(:create_page)
    end

    it "sets all headers including user agent on the page" do
      request_headers = Browser::HEADERS.merge({ "User-Agent" => "test-agent" })
      allow(described_class).to receive(:request_headers).and_return(request_headers)

      described_class.send(:create_page)

      expect(headers_double).to have_received(:set).with(request_headers)
    end
  end
end
