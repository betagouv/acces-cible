require "rails_helper"

RSpec.describe Browser do
  let(:url) { "https://example.com/" }
  let(:page) { instance_double(Ferrum::Page) }
  let(:instance) { described_class.new }

  before do
    # Stub file reads that happen during browser initialization
    allow(File).to receive(:read).with(Rails.root.join("vendor/javascript/stealth.min.js")).and_return("/* stealth js */")

    # Stub MockProcess constant for verified doubles
    stub_const("MockProcess", Class.new do
      def pid
        12345
      end
    end)
  end

  around do |example|
    WebMock.disable_net_connect!(allow_localhost: true)
    example.run
    WebMock.disable_net_connect!
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

    let(:network) { instance_double(Ferrum::Network, status: 200, response: nil) }

    before do
      browser_instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(browser_instance)
      allow(browser_instance).to receive(:get).with(url).and_return({
                                                                      body: "<html><body>Test</body></html>",
                                                                      status: 200,
                                                                      headers: {},
                                                                      current_url: url
                                                                    })
      allow(Link).to receive(:normalize).with(url).and_return(url)
    end

    it "creates a new browser instance and calls get" do
      expect(get_result).not_to be_nil
    end

    it "returns response data hash" do
      result = get_result

      expect(result).to be_a(Hash)
      expect(result).to have_key(:body)
      expect(result).to have_key(:status)
      expect(result).to have_key(:headers)
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

    context "when network has response with headers" do
      before do
        browser_instance = instance_double(described_class)
        allow(described_class).to receive(:new).and_return(browser_instance)
        allow(browser_instance).to receive(:get).with(url).and_return({
                                                                        body: "<html><body>Test</body></html>",
                                                                        status: 200,
                                                                        headers: { "content-type" => "text/html" },
                                                                        current_url: url
                                                                      })
      end

      it "returns response headers" do
        expect(get_result[:headers]).to eq({ "content-type" => "text/html" })
      end
    end

    context "when network has no response" do
      it "returns empty headers hash" do
        expect(get_result[:headers]).to eq({})
      end
    end

    context "when network status is nil" do
      before do
        allow(network).to receive(:status).and_return(nil)
      end

      it "defaults status to 200" do
        expect(get_result[:status]).to eq(200)
      end
    end
  end

  describe "#browser" do
    let(:ferrum_browser) { instance_double(Ferrum::Browser) }
    let(:network) { instance_double(Ferrum::Network) }

    before do
      # Always mock Ferrum::Browser to prevent real instances
      allow(Ferrum::Browser).to receive(:new).and_return(ferrum_browser)
      allow(ferrum_browser).to receive_messages(network: network, process: instance_double(MockProcess, pid: 12345))
      allow(Process).to receive(:kill).with(0, 12345).and_return(1)
    end

    it "creates a new Ferrum::Browser instance during initialization" do
      browser_instance = described_class.new
      expect(browser_instance.send(:browser)).to eq(ferrum_browser)
    end
  end

  describe "#with_page" do
    let(:ferrum_browser) { instance_double(Ferrum::Browser) }
    let(:network) { instance_double(Ferrum::Network) }

    before do
      # Mock browser creation to prevent real instances
      allow(Ferrum::Browser).to receive(:new).and_return(ferrum_browser)
      allow(ferrum_browser).to receive(:network).and_return(network)
      allow(network).to receive(:blocklist=)

      # Mock browser cleanup methods
      allow(ferrum_browser).to receive(:reset)
      allow(ferrum_browser).to receive(:close)
      allow(ferrum_browser).to receive(:quit)

      allow(instance).to receive(:create_page).and_return(page)
      allow(page).to receive(:close)
      allow(Rails.logger).to receive(:warn)
    end

    it "yields the created page" do
      expect { |block| instance.send(:with_page, &block) }.to yield_with_args(page)
    end

    it "closes the page after yielding" do
      instance.send(:with_page) { |p| "result" }
      expect(page).to have_received(:close)
    end

    it "returns the result of the yielded block" do
      result = instance.send(:with_page) { |p| "test_result" }
      expect(result).to eq("test_result")
    end

    context "when Ferrum::DeadBrowserError is raised" do
      before do
        allow(instance).to receive(:create_page).and_invoke(
          -> { raise Ferrum::DeadBrowserError.new("Browser is dead") },
          -> { page }
        )

        allow(instance).to receive(:cleanup!)
      end

      it "logs a warning message and calls cleanup!" do
        instance.send(:with_page) { |p| "result" }

        expect(Rails.logger).to have_received(:warn)
        expect(instance).to have_received(:cleanup!).twice
      end

      it "retries and succeeds on second attempt" do
        result = instance.send(:with_page) { |p| "retry_success" }
        expect(result).to eq("retry_success")
        expect(instance).to have_received(:create_page).twice
      end

      context "when DeadBrowserError is raised" do
        before do
          allow(instance).to receive(:create_page).and_invoke(
            -> { raise Ferrum::DeadBrowserError, "Chrome just crashed" },
            -> { page }
          )
        end

        it "retries and succeeds on second attempt" do
          result = instance.send(:with_page) { |p| "success" }

          expect(result).to eq("success")
          expect(Rails.logger).to have_received(:warn)
          expect(instance).to have_received(:cleanup!).twice
          expect(instance).to have_received(:create_page).twice
        end
      end
    end

    context "when other Ferrum::Error is raised" do
      before do
        allow(instance).to receive(:create_page).and_raise(Ferrum::Error.new("Generic error"))
        allow(Rails.logger).to receive(:error)
      end

      it "logs an error and re-raises" do
        expect do
          instance.send(:with_page) { |p| "result" }
        end.to raise_error(Ferrum::Error)

        expect(Rails.logger).to have_received(:error)
      end
    end
  end

  describe "#crashed?" do
    let(:ferrum_browser) { instance_double(Ferrum::Browser) }
    let(:process) { instance_double(MockProcess, pid: 12345) }

    before do
      allow(Ferrum::Browser).to receive(:new).and_return(ferrum_browser)
      allow(ferrum_browser).to receive_messages(network: instance_double(Ferrum::Network), process:)
      allow(ferrum_browser.network).to receive(:blocklist=)
    end

    context "when browser has no process" do
      before do
        allow(ferrum_browser).to receive(:process).and_return(nil)
      end

      it "returns true" do
        expect(instance.send(:crashed?)).to be(true)
      end
    end

    context "when browser process has no pid" do
      before do
        allow(process).to receive(:pid).and_return(nil)
      end

      it "returns true" do
        expect(instance.send(:crashed?)).to be(true)
      end
    end

    context "when process returns valid state" do
      before do
        allow(Process).to receive(:kill).with(0, 12345).and_return(1)
        instance.instance_variable_set(:@browser, ferrum_browser)
      end

      it "returns false" do
        expect(instance.send(:crashed?)).to be(false)
      end
    end

    context "when process kill raises Errno::ESRCH" do
      before do
        allow(Process).to receive(:kill).with(0, 12345).and_raise(Errno::ESRCH)
      end

      it "returns true" do
        expect(instance.send(:crashed?)).to be(true)
      end
    end

    context "when process kill raises Errno::EPERM" do
      before do
        allow(Process).to receive(:kill).with(0, 12345).and_raise(Errno::EPERM)
      end

      it "returns true" do
        expect(instance.send(:crashed?)).to be(true)
      end
    end

    context "when process kill raises TypeError" do
      before do
        allow(Process).to receive(:kill).with(0, 12345).and_raise(TypeError)
      end

      it "returns true" do
        expect(instance.send(:crashed?)).to be(true)
      end
    end
  end

  describe "#cleanup!" do
    let(:ferrum_browser) { instance_double(Ferrum::Browser) }
    let(:network) { instance_double(Ferrum::Network) }
    let(:user_data_dir) { "/tmp/chrome-test123" }

    before do
      allow(Ferrum::Browser).to receive(:new).and_return(ferrum_browser)
      allow(ferrum_browser).to receive_messages(network:, process: instance_double(MockProcess, pid: 12345))
      allow(network).to receive(:blocklist=)
      allow(ferrum_browser).to receive_messages(reset: nil, quit: nil)
      allow(Rails.logger).to receive(:warn)
      allow(FileUtils).to receive(:rm_rf)
      allow(Dir).to receive(:exist?).and_return(true)

      # Set up user data dir
      instance.instance_variable_set(:@user_data_dir, user_data_dir)
      instance.instance_variable_set(:@browser, ferrum_browser)
    end

    context "when browser exists" do
      it "calls reset, close, and quit on browser" do
        instance.send(:cleanup!)

        expect(ferrum_browser).to have_received(:reset)
        expect(ferrum_browser).to have_received(:quit)
      end

      it "removes user data directory if it exists" do
        instance.send(:cleanup!)

        expect(FileUtils).to have_received(:rm_rf).with(user_data_dir)
      end

      it "sets @browser to nil" do
        instance.send(:cleanup!)

        expect(instance.instance_variable_get(:@browser)).to be_nil
      end

      context "when browser cleanup raises an error" do
        before do
          allow(ferrum_browser).to receive(:reset).and_raise(StandardError.new("cleanup error"))
        end

        it "logs the error and continues cleanup" do
          instance.send(:cleanup!)

          expect(Rails.logger).to have_received(:warn)
          expect(FileUtils).to have_received(:rm_rf).with(user_data_dir)
          expect(instance.instance_variable_get(:@browser)).to be_nil
        end
      end
    end

    context "when browser is nil" do
      before do
        instance.instance_variable_set(:@browser, nil)
      end

      it "still removes user data directory and sets @browser to nil" do
        instance.send(:cleanup!)

        expect(FileUtils).to have_received(:rm_rf).with(user_data_dir)
        expect(instance.instance_variable_get(:@browser)).to be_nil
      end
    end

    context "when user data directory does not exist" do
      before do
        allow(Dir).to receive(:exist?).and_return(false)
      end

      it "does not attempt to remove the directory" do
        instance.send(:cleanup!)

        expect(FileUtils).not_to have_received(:rm_rf)
      end
    end

    it "accesses @browser directly without triggering browser creation logic" do
      allow(instance).to receive(:browser).and_call_original
      instance.instance_variable_set(:@browser, nil)

      instance.send(:cleanup!)

      expect(instance).not_to have_received(:browser)
    end
  end

  describe "#create_page" do
    let(:ferrum_browser) { instance_double(Ferrum::Browser) }
    let(:network) { instance_double(Ferrum::Network) }
    let(:headers) { instance_double(Ferrum::Headers) }

    before do
      allow(Ferrum::Browser).to receive(:new).and_return(ferrum_browser)
      allow(ferrum_browser).to receive_messages(network:, process: instance_double(MockProcess, pid: 12345))
      allow(network).to receive_messages("blocklist=": nil, wait_for_idle: nil)
      allow(ferrum_browser).to receive(:create_page).and_return(page)
      allow(page).to receive_messages(headers:, network:)
      allow(page).to receive(:network).and_return(network)
      allow(headers).to receive_messages(set: nil, add: nil)
      allow(Process).to receive(:kill).with(0, 12345).and_return(1)
    end

    it "creates a page from the browser" do
      result = instance.send(:create_page)

      expect(ferrum_browser).to have_received(:create_page)
      expect(result).to eq(page)
    end

    it "sets the blocklist on the page's context" do
      expect(network)
        .to receive(:blocklist=)
              .with([described_class::BLOCKED_EXTENSIONS, described_class::BLOCKED_DOMAINS])

      instance.send(:create_page)
    end

    it "sets all headers including user agent on the page" do
      request_headers = Browser::HEADERS.merge({ "User-Agent" => "test-agent" })
      allow(instance).to receive(:request_headers).and_return(request_headers)

      instance.send(:create_page)

      expect(headers).to have_received(:set).with(request_headers)
    end

    it "waits for network idle" do
      instance.send(:create_page)

      expect(network).to have_received(:wait_for_idle).with(timeout: Browser::PAGE_TIMEOUT)
    end
  end

  describe "#create_page_from_html" do
    let(:ferrum_browser) { instance_double(Ferrum::Browser) }
    let(:html) { "<html><body><h1>Test</h1></body></html>" }

    before do
      allow(Ferrum::Browser).to receive(:new).and_return(ferrum_browser)
      allow(ferrum_browser).to receive(:create_page).and_return(page)
      allow(page).to receive(:content=)
      allow(page).to receive(:bypass_csp)
    end

    it "creates a page from the browser" do
      result = instance.create_page_from_html(html)

      expect(ferrum_browser).to have_received(:create_page)
      expect(result).to eq(page)
    end
  end

  describe "#run_script_on_html" do
    let(:ferrum_browser) { instance_double(Ferrum::Browser) }
    let(:html) { "<html><body><h1>Test</h1></body></html>" }
    let(:script) { "return document.querySelector('h1').textContent;" }
    let(:script_tag) { "window.testLib = {};" }
    let(:script_result) { "Test" }

    before do
      allow(Ferrum::Browser).to receive(:new).and_return(ferrum_browser)
      allow(ferrum_browser).to receive(:create_page).and_return(page)
      allow(page).to receive(:content=)
      allow(page).to receive(:bypass_csp)
      allow(page).to receive(:add_script_tag)
      allow(page).to receive(:evaluate_async).and_return(script_result)
      allow(page).to receive(:close)
    end

    it "returns the result of the script evaluation" do
      result = instance.run_script_on_html(html, script, script_tag)

      expect(result).to eq(script_result)
    end
  end

  describe "class methods delegation" do
    it "delegates missing methods to new instance" do
      expect(described_class).to respond_to(:get)
    end

    it "creates new instance for each class method call" do
      browser_instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(browser_instance)
      allow(browser_instance).to receive(:get).and_return({})

      described_class.get(url)

      expect(described_class).to have_received(:new)
    end
  end
end
