require 'rails_helper'

RSpec.describe FetchHomePageJob do
  subject(:fetch_home_page_job) do
    perform_enqueued_jobs(only: described_class) do
      described_class.perform_later(audit)
    end
  end

  let(:audit) { create(:audit) }

  before do
    allow(Browser).to receive(:get).and_return :response_object
    allow(Audit).to receive(:find).with(audit.id.to_s).and_return(audit)
    allow(audit).to receive(:update_home_page!)
  end

  it "calls Browser.get with the audit URL" do
    fetch_home_page_job

    expect(Browser).to have_received(:get).with(audit.url)
  end

  it "stores the home page on the audit" do
    fetch_home_page_job

    expect(audit).to have_received(:update_home_page!).with(:response_object)
  end

  it "enqueues a run of ProcessAuditJob" do
    expect { fetch_home_page_job }
      .to have_enqueued_job(ProcessAuditJob)
      .exactly(:once)
      .with(audit)
  end

  describe "error cases" do
    before do
      allow(Browser).to receive(:get).and_raise(error)
    end

    context "when the ressource does not exist" do
      let(:error) { Ferrum::StatusError.new(audit.url) }

      it "still calls ProcessAuditJob" do
        expect { fetch_home_page_job }.to raise_error do |_err|
          expect(ProcessAuditJob).to have_been_enqueued.exactly(:once).with(audit)
        end
      end
    end
  end
end
