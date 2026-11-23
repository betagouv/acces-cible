# frozen_string_literal: true

require "rails_helper"

RSpec.describe FetchHomePageService do
  subject(:fetch!) { described_class.new(audit) }

  let(:audit) { create(:audit, :without_checks) }

  before do
    allow(Browser).to receive(:get).and_return(
      current_url: "www.example.com", body: "foobar", status: 200, content_type: "text/html"
    )
  end

  it "calls Browser.get with the site URL" do
    fetch!

    expect(Browser).to have_received(:get).with(audit.site.url)
  end

  it "stores a page snapshot with the fetched data" do
    fetch!

    expect(audit.page_snapshots.find_by(kind: "home")).to have_attributes(
      requested_url: audit.site.url,
      current_url: "www.example.com",
      html: "foobar",
      status: 200,
      content_type: "text/html"
    )
  end

  it "updates the audit's home page url" do
    fetch!

    expect(audit.reload.home_page_url).to eq("www.example.com")
  end

  context "when the navigation fails" do
    let(:error) do
      Browser::NavigationError.new("failed", status: 403, net_error: "net::ERR_HTTP_RESPONSE_CODE_FAILURE")
    end

    before do
      allow(Browser).to receive(:get).and_raise(error)
    end

    it "stores a home page snapshot with the status and the net error" do
      fetch!

      expect(audit.page_snapshots.find_by(kind: "home")).to have_attributes(
        requested_url: audit.site.url,
        html: nil,
        status: 403,
        net_error: "net::ERR_HTTP_RESPONSE_CODE_FAILURE"
      )
    end
  end
end
