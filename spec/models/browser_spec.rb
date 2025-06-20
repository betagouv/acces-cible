require "rails_helper"

RSpec.describe Browser do
  let(:url) { "https://example.com/" }
  let(:browser) { described_class.new }
  let(:status) { 200 }
  let(:headers) { { "content-type" => "text/html" } }
  # rubocop:disable RSpec/VerifiedDoubles
  let(:ferrum) { double("ferrum").as_null_object }
  let(:page) { double("page").as_null_object }
  let(:network) { double("network").as_null_object }
  let(:response) { double("response") }
  # rubocop:enable RSpec/VerifiedDoubles

  before do
    allow(Ferrum::Browser).to receive(:new).and_return(ferrum)
    allow(ferrum).to receive_messages(network:, create_page: page)
    allow(page).to receive(:network).and_return(network)
    allow(network).to receive_messages(status:, response:)
    allow(response).to receive(:headers).and_return(headers) if response
  end

  describe "#get" do
    subject(:get) { browser.get(url) }

    let(:body) { "<html><body>Test</body></html>" }

    before do
      allow(page).to receive_messages(body:, current_url: url)
    end

    context "with a successful request", :aggregate_failures do
      it "returns response data for the provided URL" do
        expect(page).to receive(:go_to).with(url)
        expect(get).to eq({ body:, status:, headers:, current_url: url })
      end
    end

    context "when network response is nil" do
      let(:response) { nil }

      it "handles missing network response gracefully" do
        expect(get[:headers]).to eq({})
      end
    end

    context "when network status is nil" do
      let(:status) { nil }
      let(:headers) { {} }

      it "defaults status to 200" do
        expect(get[:status]).to eq(200)
      end
    end

    context "when browser encounters an error" do
      before do
        allow(page).to receive(:go_to).and_raise(Ferrum::TimeoutError.new("Timeout"))
      end

      it "logs the error and re-raises it" do
        expect(Rails.logger).to receive(:error)
        expect { get }.to raise_error(Ferrum::TimeoutError)
      end
    end
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe "#axe_check", :aggregate_failures do
    subject(:axe_check) { browser.axe_check(url) }

    let(:axe_source) { "/* axe source code */" }
    let(:axe_locale) { '{"lang": "fr"}' }
    let(:axe_results) do
      {
        "violations" => [
          { "id" => "document-title" },
          { "id" => "html-has-lang" }
        ],
        "passes" => []
      }
    end

    before do
      allow(File).to receive(:read).with(Browser::AXE_SOURCE_PATH).and_return(axe_source)
      allow(File).to receive(:read).with(Browser::AXE_LOCALE_PATH).and_return(axe_locale)
      allow(page).to receive(:bypass_csp)
      allow(page).to receive(:add_script_tag).with(content: axe_source)
      allow(page).to receive(:evaluate_async).and_return(axe_results)
    end

    it "runs localized Axe checks on the provided URL, bypassing CSP" do
      expect(page).to receive(:go_to).with(url)
      expect(page).to receive(:bypass_csp)
      expect(page).to receive(:add_script_tag).with(content: axe_source)
      expect(page).to receive(:evaluate_async).with(
        include("axe.configure({locale: #{axe_locale} })"),
        Browser::PAGE_TIMEOUT
      )
      results = axe_check

      expect(results).to be_a(Hash)
      expect(results).to have_key("violations")
      expect(results).to have_key("passes")
      expect(results["violations"]).to be_an(Array)
      expect(results["passes"]).to be_an(Array)
    end

    context "when browser encounters a timeout" do
      before do
        allow(page).to receive(:go_to).and_raise(Ferrum::TimeoutError.new("Timeout"))
      end

      it "logs the error and re-raises it" do
        expect(Rails.logger).to receive(:error)
        expect { axe_check }.to raise_error(Ferrum::TimeoutError)
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
