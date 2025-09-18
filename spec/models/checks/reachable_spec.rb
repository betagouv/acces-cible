require "rails_helper"

RSpec.describe Checks::Reachable do
  let(:check) { described_class.new }
  let(:original_url) { "https://example.com" }
  let(:redirect_url) { "https://example.org" }
  let(:audit) { instance_double(Audit, url: original_url, update: true) }
  let(:root_page) { instance_double(Page) }
  let(:site) { build(:site) }

  before do
    allow(check).to receive_messages(audit:, root_page:, site:)
  end

  describe "constants" do
    it "sets PRIORITY to 0" do
      expect(described_class::PRIORITY).to eq(0)
    end
  end

  describe "#custom_badge_status" do
    subject(:status) { described_class.new(data: { original_url:, redirect_url: }).send(:custom_badge_status) }

    context "when there is a redirect_url" do
      it { should eq(:info) }
    end

    context "when there is no redirect_url" do
      let(:redirect_url) { nil }

      it { should eq(:success) }
    end
  end

  describe "#analyze!" do
    let(:reachable) { true }
    let(:redirects) { false }

    before do
      allow(root_page).to receive_messages(success?: reachable, redirected?: redirects, title: "Page title", status: 200)
      allow(site).to receive_messages(update: true)
    end

    context "when the site is reachable" do
      context "when the site has a blank name" do
        it "updates the site name" do
          expect(site).to receive(:update).with(name: root_page.title)

          check.send(:analyze!)
        end
      end

      context "when the site already has a name" do
        it "doesn't update site name" do
          allow(site).to receive(:name).and_return("Site name already set")
          expect(site).not_to receive(:update)

          check.send(:analyze!)
        end
      end

      context "when the page does not redirect" do
        let(:redirects) { false }

        it "returns an empty hash" do
          expect(check.send(:analyze!)).to eq({})
        end
      end

      context "when the page redirects" do
        before do
          allow(root_page).to receive_messages(redirected?: true, url: original_url, actual_url: redirect_url)
        end

        it "updates the audit with the new URL" do
          expect(audit).to receive(:update).with(url: redirect_url)
          check.send(:analyze!)
        end

        it "returns a hash with the original and redirect URLs" do
          result = check.send(:analyze!)
          expect(result).to eq({ original_url:, redirect_url: })
        end
      end
    end

    context "when the site is not reachable" do
      context "when the page has a status (HTTP error)" do
        before do
          allow(root_page).to receive_messages(success?: false, status: 404)
        end

        it "returns nil" do
          expect(check.send(:analyze!)).to be_nil
        end
      end

      context "when the page has no status (browser/connection error)" do
        before do
          allow(root_page).to receive_messages(success?: false, status: nil)
        end

        it "raises a BrowserError" do
          expect {
            check.send(:analyze!)
          }.to raise_error(Checks::Reachable::BrowserError, "Browser error preventing getting #{original_url}")
        end
      end
    end
  end

  describe "#redirected?" do
    subject(:redirected) { described_class.new(data: { original_url:, redirect_url: }).redirected? }

    context "when going from https to http" do
      let(:original_url) { "https://www.example.com/" }
      let(:redirect_url) { "http://www.example.com/" }

      it { should be false }
    end

    context "when going from http to https" do
      let(:original_url) { "http://www.example.com/" }
      let(:redirect_url) { "https://www.example.com/" }

      it { should be false }
    end

    context "when going from naked domain to www" do
      let(:original_url) { "https://example.com/" }
      let(:redirect_url) { "https://www.example.com/" }

      it { should be false }
    end

    context "when going from www to naked domain" do
      let(:original_url) { "https://www.example.com/" }
      let(:redirect_url) { "https://example.com/" }

      it { should be false }
    end

    context "when going from one domain to another" do
      let(:original_url) { "https://www.example.com/" }
      let(:redirect_url) { "https://www.foo.bar/" }

      it { should be true }
    end

    context "when going from root to a folder" do
      let(:original_url) { "https://www.example.com/" }
      let(:redirect_url) { "https://www.example.com/foo/" }

      it { should be true }
    end
  end
end
