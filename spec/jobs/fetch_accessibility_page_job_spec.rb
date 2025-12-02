require "rails_helper"

RSpec.describe FetchAccessibilityPageJob do
  subject(:fetch_accessibility_page_job) do
    perform_enqueued_jobs(only: described_class) do
      described_class.perform_later(audit)
    end
  end

  let(:audit) { create(:audit) }
  let(:service) { instance_double(FindAccessibilityPageService) }

  before do
    allow(FindAccessibilityPageService).to receive(:new).with(audit).and_return(service)
    allow(Audit).to receive(:find).with(audit.id.to_s).and_return(audit)
  end

  context "when the service finds a page" do
    let(:page) { build(:page, url: "https://example.com/accessibility", html: "<html>Body</html>") }

    before do
      allow(service).to receive(:call).and_return(page)
      allow(audit).to receive(:update_accessibility_page!)
    end

    it "stores the accessibility page on the audit" do
      fetch_accessibility_page_job

      expect(audit).to have_received(:update_accessibility_page!).with(page.url, page.html)
    end

    it "enqueues a run of ProcessAuditJob" do
      expect { fetch_accessibility_page_job }.to have_enqueued_job(ProcessAuditJob).with(audit)
    end
  end

  context "when no page is found" do
    before do
      allow(service).to receive(:call).and_return(nil)
      allow(audit).to receive(:update_accessibility_page!)
    end

    it "does not update the accessibility page" do
      fetch_accessibility_page_job

      expect(audit).not_to have_received(:update_accessibility_page!)
    end

    it "still enqueues ProcessAuditJob" do
      expect { fetch_accessibility_page_job }.to have_enqueued_job(ProcessAuditJob).with(audit)
    end
  end

  describe "error cases" do
    before do
      allow(service).to receive(:call).and_raise(error)
    end

    context "when Ferrum returns a StatusError" do
      let(:error) { Ferrum::StatusError.new(audit.url) }

      it "does not crash" do
        expect { fetch_accessibility_page_job }.not_to raise_error
      end

      it "still calls ProcessAuditJob" do
        fetch_accessibility_page_job

        expect(ProcessAuditJob).to have_been_enqueued.with(audit)
      end
    end

    context "when Ferrum returns a TimeoutError" do
      let(:error) { Ferrum::TimeoutError.new("timeout") }

      it "does not crash" do
        expect { fetch_accessibility_page_job }.not_to raise_error
      end

      it "still calls ProcessAuditJob" do
        fetch_accessibility_page_job

        expect(ProcessAuditJob).to have_been_enqueued.with(audit)
      end
    end
  end
end
