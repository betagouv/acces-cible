require 'rails_helper'

RSpec.describe ProcessAuditJob do
  let(:site) { create(:site) }
  let(:audit) { create(:audit, site: site) }

  # we want to control the output of `audit.checks` (otherwise lots of
  # things will break when we update the default checks) and that is
  # very hard to mock (mocking A/R scopes is essentially a bad
  # idea). In the meantime, remove all checks and add ours, it's not
  # great but it works.
  before "remove all existing checks" do
    audit.checks.destroy_all
  end

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
