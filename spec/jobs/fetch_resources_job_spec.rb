# frozen_string_literal: true

require "rails_helper"

describe FetchResourcesJob do
  subject(:fetch_resources_job) do
    perform_enqueued_jobs(only: described_class) do
      described_class.perform_later(audit)
    end
  end

  let(:audit) { create(:audit, home_page_url: "https://example.com/") }

  before do
    allow(FetchHomePageService).to receive(:new).with(audit)
    allow(FindAccessibilityPageService).to receive(:new).with(audit)
  end

  it "calls the service for the home page" do
    fetch_resources_job

    expect(FetchHomePageService).to have_received(:new).with(audit)
  end

  it "calls the service for the accessibility page" do
    fetch_resources_job

    expect(FindAccessibilityPageService).to have_received(:new).with(audit)
  end

  context "when the home page could not be fetched" do
    let(:audit) { create(:audit, home_page_url: nil) }

    it "does not call the service for the accessibility page" do
      fetch_resources_job

      expect(FindAccessibilityPageService).not_to have_received(:new)
    end
  end

  it "enqueues a run of ProcessAuditJob" do
    expect { fetch_resources_job }
      .to have_enqueued_job(ProcessAuditJob)
      .exactly(:once)
      .with(audit)
  end

  describe "error cases" do
    before do
      allow(Browser).to receive(:get).and_raise(error)
    end

    context "when the ressource does not exist" do
      let(:error) { Browser::NavigationError.new("failed", status: nil, net_error: "net::ERR_NAME_NOT_RESOLVED") }

      it "does not crash" do
        expect { fetch_resources_job }.not_to raise_error
      end

      it "still calls ProcessAuditJob" do
        fetch_resources_job

        expect(ProcessAuditJob).to have_been_enqueued.exactly(:once).with(audit)
      end
    end
  end
end
