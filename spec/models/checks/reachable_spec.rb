require "rails_helper"

RSpec.describe Checks::Reachable do
  let(:check) { described_class.new }
  let(:original_url) { "https://example.com/" }
  let(:home_page_url) { original_url }
  let(:home_page_snapshot) { build(:page_snapshot) }
  let(:site) { create(:site, url: original_url) }
  let(:audit) { build(:audit, site:, home_page_url:) }

  before do
    allow(check).to receive_messages(audit:, site:)
    allow(audit).to receive(:home_page_snapshot).and_return(home_page_snapshot)
  end

  describe "constants" do
    it "sets PRIORITY to 0" do
      expect(described_class::PRIORITY).to eq(0)
    end
  end

  describe "#custom_badge_status" do
    subject(:status) { check.send(:custom_badge_status) }

    context "when the page redirects" do
      let(:home_page_url) { "https://www.redirection.org/" }

      before { check.found = true }

      it { is_expected.to eq(:success) }
    end

    context "when the site is reachable" do
      before { check.found = true }

      it { is_expected.to eq(:success) }
    end

    context "when the site is not reachable" do
      before { check.found = false }

      it { is_expected.to eq(:error) }
    end
  end

  describe "#analyze!" do
    context "when the site is reachable" do
      context "when the page does not redirect" do
        let(:home_page_url) { original_url }

        it "returns an empty hash" do
          expect(check.send(:analyze!)).to eq({})
        end
      end

      context "when the page redirects" do
        let(:home_page_url) { "https://www.redirection.org/" }

        it "returns a hash with the original and redirect URLs" do
          result = check.send(:analyze!)
          expect(result).to eq({ original_url:, redirect_url: home_page_url })
        end
      end

      context "when the site responded with an HTTP error and no content" do
        let(:home_page_snapshot) { build(:page_snapshot, html: nil, status: 403) }

        it "returns an empty hash" do
          expect(check.send(:analyze!)).to eq({})
        end
      end
    end

    context "when the site is not reachable" do
      context "when the site did not respond" do
        let(:home_page_snapshot) { build(:page_snapshot, html: nil, status: nil) }

        it "returns nil" do
          expect(check.send(:analyze!)).to be_nil
        end
      end

      context "when there is no home page snapshot" do
        let(:home_page_snapshot) { nil }

        it "returns nil" do
          expect(check.send(:analyze!)).to be_nil
        end
      end
    end
  end

  describe "#redirected?" do
    subject(:redirected) { check.redirected? }

    context "when going from https to http" do
      let(:original_url) { "https://www.example.com/" }
      let(:home_page_url) { "http://www.example.com/" }

      it { is_expected.to be_falsey }
    end

    context "when going from http to https" do
      let(:original_url) { "http://www.example.com/" }
      let(:home_page_url) { "https://www.example.com/" }

      it { is_expected.to be_falsey }
    end

    context "when going from naked domain to www" do
      let(:original_url) { "https://example.com/" }
      let(:home_page_url) { "https://www.example.com/" }

      it { is_expected.to be_falsey }
    end

    context "when going from www to naked domain" do
      let(:original_url) { "https://www.example.com/" }
      let(:home_page_url) { "https://example.com/" }

      it { is_expected.to be_falsey }
    end

    context "when going from one domain to another" do
      let(:original_url) { "https://www.example.com/" }
      let(:home_page_url) { "https://www.foo.bar/" }

      it { is_expected.to be_truthy }
    end

    context "when going from root to a folder" do
      let(:original_url) { "https://www.example.com/" }
      let(:home_page_url) { "https://www.example.com/foo/" }

      it { is_expected.to be_truthy }
    end
  end
end
