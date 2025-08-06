require "rails_helper"

RSpec.describe Browser do
  let(:url) { "https://example.com/" }
  let(:page) { instance_double(Ferrum::Page) }
  let(:instance) { described_class.instance }

  around do |example|
    WebMock.disable_net_connect!(allow_localhost: true)
    example.run
    WebMock.disable_net_connect!
  end

  describe "#get" do
    subject(:get_result) { described_class.get(url) }

    let(:network) { instance_double(Ferrum::Network, status: 200, response: nil) }

    before do
      allow(instance).to receive(:with_page).and_yield(page)
      allow(page).to receive(:go_to)
      allow(page).to receive_messages(body: "<html><body>Test</body></html>", network: network, current_url: url)
      allow(Link).to receive(:normalize).with(url).and_return(url)
    end

    it "navigates to the provided URL" do
      expect(page).to receive(:go_to).with(url)
      get_result
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
      expect(Link).to receive(:normalize).with(url)
      expect(get_result[:current_url]).to eq(url)
    end

    context "when network has response with headers" do
      let(:response) { double("Response", headers: { "content-type" => "text/html" }) } # rubocop:disable RSpec/VerifiedDoubles
      let(:network) { instance_double(Ferrum::Network, status: 200, response:) }

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

  describe "#axe_check" do
    subject(:axe_check) { described_class.axe_check(url) }

    let(:ferrum_browser) { instance.browser }
    let(:page) { ferrum_browser.create_page }
    let(:html) do
      <<~HTML
        <!DOCTYPE html>
        <html> <!-- 1. Missing lang attribute -->
          <head></head> <!-- 2. Missing title tag -->
          <body>
            <img src="test.jpg"> <!-- 3. Missing alt attribute -->
            <a href="/target"></a>  <!-- 4. Missing text -->
            <input name="email"> <!-- 5. Missing associated label -->
          </body>
        </html>
      HTML
    end

    before do
      allow(instance).to receive(:with_page).and_yield(page)

      allow(page).to receive(:go_to) do |_url|
        page.evaluate("document.documentElement.innerHTML = `#{html}`")
      end
    end

    it "visits the provided URL" do
      expect(page).to receive(:go_to).with(url)
      axe_check
    end

    it "bypasses Content Security Policy" do
      expect(page).to receive(:bypass_csp).and_call_original
      axe_check
    end

    it "returns accessibility results" do
      results = axe_check

      expect(results).to be_a(Hash)
      expect(results).to have_key("violations")
      expect(results).to have_key("passes")

      violation_ids = results["violations"].collect { |rule| rule["id"] }
      expected_ids = ["document-title", "html-has-lang", "image-alt", "label", "landmark-one-main", "link-name", "page-has-heading-one", "region"]
      expect(violation_ids).to match_array(expected_ids)
    end

    context "when browser encounters a timeout" do
      before do
        allow(instance).to receive(:with_page).and_raise(Ferrum::TimeoutError.new("Timeout"))
      end

      it "raises the timeout error" do
        expect { axe_check }.to raise_error(Ferrum::TimeoutError)
      end
    end
  end

  describe "#browser" do
    let(:ferrum_browser) { instance_double(Ferrum::Browser) }
    let(:network) { instance_double(Ferrum::Network) }

    before do
      allow(Ferrum::Browser).to receive(:new).and_return(ferrum_browser)
      allow(ferrum_browser).to receive(:network).and_return(network)
      allow(network).to receive(:blocklist=)

      # Reset the memoized browser instance
      instance.instance_variable_set(:@browser, nil)
    end

    it "creates a new Ferrum::Browser instance" do
      expect(Ferrum::Browser).to receive(:new)
      instance.browser
    end

    it "sets network blocklist with extensions and domains" do
      instance.browser
      expect(network).to have_received(:blocklist=).with([described_class::BLOCKED_EXTENSIONS, described_class::BLOCKED_DOMAINS])
    end

    it "memoizes the browser instance" do
      first_browser = instance.browser
      second_browser = instance.browser

      expect(first_browser).to be(second_browser)
      expect(Ferrum::Browser).to have_received(:new).once
    end

    it "returns the Ferrum::Browser instance" do
      expect(instance.browser).to eq(ferrum_browser)
    end
  end

  describe "#with_page" do
    before do
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
        call_count = 0
        allow(instance).to receive(:create_page) do
          call_count += 1
          if call_count == 1
            raise Ferrum::DeadBrowserError.new("Browser is dead")
          else
            page
          end
        end

        allow(instance).to receive(:restart!)
      end

      it "logs a warning message" do
        instance.send(:with_page) { |p| "result" }
        expect(Rails.logger).to have_received(:warn)
      end

      it "calls restart" do
        instance.send(:with_page) { |p| "result" }
        expect(instance).to have_received(:restart!)
      end

      it "retries and succeeds on second attempt" do
        result = instance.send(:with_page) { |p| "retry_success" }
        expect(result).to eq("retry_success")
        expect(instance).to have_received(:create_page).twice
      end
    end

    context "when Ferrum::TimeoutError is raised" do
      context "when create_page raises timeout error" do
        before do
          allow(instance).to receive(:create_page).and_raise(Ferrum::TimeoutError.new("Timeout"))
        end

        it "logs a warning and re-raises when page is not defined" do
          expect do
            instance.send(:with_page) { |p| "result" }
          end.to raise_error(Ferrum::TimeoutError)

          expect(Rails.logger).to have_received(:warn)
        end
      end

      context "when yield raises timeout error with page present" do
        before do
          allow(instance).to receive(:create_page).and_return(page)
        end

        it "logs warning and retries with existing page" do
          call_count = 0
          result = instance.send(:with_page) do |p|
            call_count += 1
            if call_count == 1
              raise Ferrum::TimeoutError.new("Timeout during yield")
            else
              "retry_result"
            end
          end

          expect(result).to eq("retry_result")
          expect(Rails.logger).to have_received(:warn)
          expect(page).to have_received(:close)
        end
      end
    end

    context "when Ferrum::PendingConnectionsError is raised" do
      before do
        allow(instance).to receive(:create_page).and_raise(Ferrum::PendingConnectionsError.new("Pending connections"))
      end

      it "logs a warning and re-raises" do
        expect do
          instance.send(:with_page) { |p| "result" }
        end.to raise_error(Ferrum::PendingConnectionsError)

        expect(Rails.logger).to have_received(:warn)
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
end
