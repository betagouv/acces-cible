require 'rails_helper'

RSpec.describe ProcessAuditJob do
  let(:site) { create(:site) }
  let(:audit) { create(:audit, :without_checks, site: site) }

  context 'when there are checks that can move to ready' do
    before do
      create(:reachable_check, audit: audit)
    end

    it 'enqueues RunCheckJob with all the checks that are ready' do
      expect { described_class.perform_now(audit) }
        .to have_enqueued_job(RunCheckJob)
              .exactly(:once)
    end
  end

  context "when there are no jobs that can move to ready" do
    before do
      create(:reachable_check, :running, audit: audit)
    end

    it "does not enqueue any job" do
      expect { described_class.perform_now(audit) }
        .not_to have_enqueued_job(RunCheckJob)
    end
  end
end
