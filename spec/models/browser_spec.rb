require "rails_helper"

RSpec.describe Browser do
  describe "#axe_check" do
    subject(:axe_check) { described_class.axe_check(url) }

    let(:url) { "https://example.com" }
    let(:ferrum_browser) { Ferrum::Browser.new(headless: true) }
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

    around do |example|
      # Allow real HTTP connections for Chrome DevTools Protocol
      WebMock.disable_net_connect!(allow_localhost: true)
      example.run
      WebMock.disable_net_connect!
    end

    before do
      allow(described_class.instance).to receive(:with_page) do |&block|
        begin
          block.call(page)
        ensure
          ferrum_browser.quit
        end
      end

      allow(page).to receive(:go_to) do |_url|
        page.evaluate("document.documentElement.innerHTML = `#{html}`")
      end
    end

    after do
      ferrum_browser.quit rescue nil
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
        allow(described_class.instance).to receive(:with_page).and_raise(Ferrum::TimeoutError.new("Timeout"))
      end

      it "raises the timeout error" do
        expect { axe_check }.to raise_error(Ferrum::TimeoutError)
      end
    end
  end
end
