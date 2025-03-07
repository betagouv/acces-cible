require "rails_helper"

RSpec.describe Checks::Reachable do
  let(:check) { described_class.new }
  let(:url) { "https://example.com" }
  let(:redirect_url) { "https://example.org" }
  let(:audit) { instance_double(Audit, url:, update: true) }
  let(:root_page) { instance_double(Page) }

  before do
    allow(check).to receive_messages(audit:, root_page:)
  end

  describe "constants" do
    it "sets PRIORITY to 0" do
      expect(described_class::PRIORITY).to eq(0)
    end
  end

  describe "#custom_badge_status" do
    context "when there is a redirect_url" do
      before do
        check.redirect_url = "https://example.org"
      end

      it "returns :info" do
        expect(check.send(:custom_badge_status)).to eq(:info)
      end
    end

    context "when there is no redirect_url" do
      before do
        check.redirect_url = nil
      end

      it "returns :success" do
        expect(check.send(:custom_badge_status)).to eq(:success)
      end
    end
  end

  describe "#analyze!" do
    context "when the site is reachable" do
      before do
        allow(root_page).to receive(:success?).and_return(true)
      end

      context "when the page does not redirect" do
        before do
          allow(root_page).to receive(:redirected?).and_return(false)
        end

        it "returns an empty hash" do
          expect(check.send(:analyze!)).to eq({})
        end
      end

      context "when the page redirects" do
        before do
          allow(root_page).to receive_messages(redirected?: true, url:, actual_url: redirect_url)
        end

        it "updates the audit with the new URL" do
          expect(audit).to receive(:update).with(url: redirect_url)
          check.send(:analyze!)
        end

        it "returns a hash with the original and redirect URLs" do
          result = check.send(:analyze!)
          expect(result).to eq({
            original_url: url,
            redirect_url: redirect_url
          })
        end
      end
    end

    context "when the site is not reachable" do
      before do
        allow(root_page).to receive_messages(success?: false, status: 404)
      end

      it "raises an UnreachableSiteError" do
        expect {
          check.send(:analyze!)
        }.to raise_error(Checks::Reachable::UnreachableSiteError, "Server response 404 when trying to get #{url}")
      end
    end
  end
end
