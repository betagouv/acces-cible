require 'rails_helper'

RSpec.describe RunCheckJob do
  let(:site) { create(:site) }
  let(:audit) { create(:audit, site: site) }
  let(:check) { audit.checks.first }
  let(:retryable_error) { Check::RETRYABLE_ERRORS.first }

  describe '#perform' do
    it 'runs check and updates audit', :aggregate_failures do
      allow(check).to receive(:run)
      allow(audit).to receive(:update_from_checks)
      allow(audit).to receive(:next_check).and_return(nil)

      described_class.new.perform(check)

      expect(check).to have_received(:run)
      expect(audit).to have_received(:update_from_checks)
    end

    context 'when more checks remain' do
      it 'reschedules itself with the next check' do
        next_check = audit.checks.last
        job = described_class.new
        allow(check).to receive(:run)
        allow(audit).to receive(:update_from_checks)
        allow(audit).to receive(:next_check).and_return(next_check)

        job_class_double = class_double(described_class)
        allow(described_class).to receive(:set).with(wait_until: kind_of(Time)).and_return(job_class_double)
        allow(job_class_double).to receive(:perform_later)

        job.perform(check)

        expect(job_class_double).to have_received(:perform_later).with(next_check)
      end
    end
  end
end
