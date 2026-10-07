require "rails_helper"

RSpec.describe Browser do
  let(:url) { "https://example.com/" }

  describe ".reachable?" do
    subject(:reachable?) { described_class.reachable?(url) }

    let(:response) { instance_double(HTTP::Response) }
    let(:status) { instance_double(HTTP::Response::Status) }

    before do
      allow(described_class).to receive(:head).with(url).and_return(response)
      allow(response).to receive(:status).and_return(status)
    end

    context "when URL is nil" do
      let(:url) { nil }

      it "returns false" do
        expect(reachable?).to be(false)
      end

      it "does not make a HEAD request" do
        reachable?
        expect(described_class).not_to have_received(:head)
      end
    end

    context "when URL is blank" do
      let(:url) { "" }

      it "returns false" do
        expect(reachable?).to be(false)
      end

      it "does not make a HEAD request" do
        reachable?
        expect(described_class).not_to have_received(:head)
      end
    end

    context "when HEAD returns success" do
      before do
        allow(status).to receive_messages(success?: true, redirect?: false)
      end

      it "returns true" do
        expect(reachable?).to be(true)
      end

      it "makes a HEAD request with the URL" do
        reachable?
        expect(described_class).to have_received(:head).with(url)
      end
    end

    context "when HEAD returns redirect" do
      before do
        allow(status).to receive_messages(success?: false, redirect?: true)
      end

      it "returns true" do
        expect(reachable?).to be(true)
      end
    end

    context "when HEAD returns neither success nor redirect" do
      before do
        allow(status).to receive_messages(success?: false, redirect?: false)
      end

      it "returns false" do
        expect(reachable?).to be(false)
      end
    end

    context "when HEAD raises an error" do
      before do
        allow(described_class).to receive(:head).with(url).and_raise(StandardError)
      end

      it "returns false" do
        expect(reachable?).to be(false)
      end
    end
  end

  describe ".head" do
    subject(:head_result) { described_class.head(url) }

    let(:response) { instance_double(HTTP::Response) }
    let(:http_chain) { instance_double(HTTP::Client) }
    let(:ssl) { { verify_mode: OpenSSL::SSL::VERIFY_NONE } }

    before do
      allow(HTTP).to receive(:headers).and_return(http_chain)
      allow(http_chain).to receive(:timeout).and_return(http_chain)
      allow(http_chain).to receive(:head).with(url, ssl:).and_return(response)
    end

    it "makes HEAD request with correct options" do
      head_result

      expect(HTTP).to have_received(:headers).with(described_class::REQUEST_HEADERS)
      expect(http_chain).to have_received(:timeout).with(connect: 3, read: 3)
      expect(http_chain).to have_received(:head).with(url, ssl:)
    end

    it "returns the HTTP response" do
      expect(head_result).to eq(response)
    end
  end

  describe ".get" do
    subject(:get_result) { described_class.get(url) }

    let(:browser_double) { instance_double(Ferrum::Browser) }
    let(:headers_double) { instance_double(Ferrum::Headers) }
    let(:network_double) { instance_double(Ferrum::Network) }
    let(:page_double) { instance_double(Ferrum::Page) }

    before do
      allow(described_class).to receive(:browser).and_return(browser_double)
      allow(browser_double).to receive(:create_page).with(new_context: true).and_yield(page_double)
      allow(headers_double).to receive(:set)
      allow(network_double).to receive(:blocklist=)
      allow(network_double).to receive_messages(status: 200, wait_for_idle: true)
      allow(page_double).to receive(:go_to).with(url).and_return("frame-id")
      allow(page_double).to receive(:evaluate).with("document.contentType").and_return("text/html")
      allow(page_double).to receive_messages(headers: headers_double, network: network_double, body: "<html><body>Test</body></html>", current_url: url)
      allow(page_double).to receive(:close)
      allow(Link).to receive(:normalize).with(url).and_return(url)
    end

    it "waits for network idle" do
      get_result

      expect(network_double).to have_received(:wait_for_idle).with(timeout: Browser::NETWORK_IDLE_TIMEOUT).once
    end

    context "when the network does not become idle" do
      before do
        allow(network_double).to receive_messages(wait_for_idle: false, traffic: [])
        allow(Rails.logger).to receive(:warn)
      end

      it "still returns the response data" do
        expect(get_result[:body]).to eq("<html><body>Test</body></html>")
      end
    end

    context "when navigation times out" do
      before do
        allow(page_double).to receive(:go_to).with(url).and_return(nil)
        allow(network_double).to receive(:traffic).and_return([])
        allow(Rails.logger).to receive(:warn)
      end

      it "skips the idle wait" do
        get_result

        expect(network_double).not_to have_received(:wait_for_idle)
      end

      it "still returns the response data" do
        expect(get_result[:body]).to eq("<html><body>Test</body></html>")
      end
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

    it "returns the document content type" do
      expect(get_result[:content_type]).to eq("text/html")
    end

    it "returns normalized current URL" do
      expect(get_result[:current_url]).to eq(url)
    end
  end

  describe "#with_page" do
    let(:browser_double) { instance_double(Ferrum::Browser) }
    let(:headers_double) { instance_double(Ferrum::Headers) }
    let(:network_double) { instance_double(Ferrum::Network) }
    let(:page_double) { instance_double(Ferrum::Page) }

    before do
      allow(described_class).to receive(:browser).and_return(browser_double)
      allow(browser_double).to receive(:create_page).with(new_context: true).and_yield(page_double)
      allow(headers_double).to receive(:set)
      allow(network_double).to receive(:blocklist=)
      allow(page_double).to receive_messages(headers: headers_double, network: network_double)
    end

    it "yields the created page" do
      expect { |block| described_class.send(:with_page, &block) }.to yield_with_args(page_double)
    end

    it "sets request headers on the page" do
      request_headers = { "Accept-Language" => "fr" }
      allow(described_class).to receive(:request_headers).and_return(request_headers)

      described_class.send(:with_page) { |p| "result" }

      expect(headers_double).to have_received(:set).with(request_headers)
    end

    it "sets the blocklist on the page" do
      described_class.send(:with_page) { |p| "result" }

      expect(network_double).to have_received(:blocklist=).with(described_class::BLOCKED_URL_PATTERNS)
    end

    it "returns the result of the yielded block" do
      result = described_class.send(:with_page) { |p| "test_result" }
      expect(result).to eq("test_result")
    end
  end
end
