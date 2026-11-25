# frozen_string_literal: true

require "rails_helper"

describe FetchResourcesJob do
  subject(:fetch_resources_job) do
    perform_enqueued_jobs(only: described_class) do
      described_class.perform_later(audit)
    end
  end

  let(:audit) { create(:audit) }

  before do
    create(:page_snapshot, audit:, kind: "home")
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

  it "enqueues a run of ProcessAuditJob" do
    expect { fetch_resources_job }
      .to have_enqueued_job(ProcessAuditJob)
      .exactly(:once)
      .with(audit)
  end

  context "when the home page cannot be audited" do
    before do
      audit.home_page_snapshot.update!(status: 404)
    end

    it "does not call the service for the accessibility page" do
      fetch_resources_job

      expect(FindAccessibilityPageService).not_to have_received(:new)
    end

    it "aborts the checks that depend on Reachable" do
      fetch_resources_job

      other_checks = audit.reload.checks.reject { |check| check.is_a?(Checks::Reachable) }
      expect(other_checks.map(&:current_state).uniq).to eq(["aborted"])
    end
  end
end
