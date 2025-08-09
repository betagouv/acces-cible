require 'rails_helper'

RSpec.describe ProcessAuditJob do
  let(:site) { create(:site) }
  let(:audit) { create(:audit, site: site) }

  describe '#perform' do
    context 'when there are checks to process' do
      it 'launches RunCheckJob with the next check' do
        check = audit.checks.first
        allow(audit).to receive(:next_check).and_return(check)
        allow(RunCheckJob).to receive(:perform_later)

        described_class.new.perform(audit)

        expect(RunCheckJob).to have_received(:perform_later).with(check)
      end
    end

    context 'when there are no checks to process' do
      it 'does not launch RunCheckJob' do
        allow(audit).to receive(:next_check).and_return(nil)
        allow(RunCheckJob).to receive(:perform_later)

        described_class.new.perform(audit)

        expect(RunCheckJob).not_to have_received(:perform_later)
      end
    end
  end
end
