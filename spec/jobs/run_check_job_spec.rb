require 'rails_helper'

RSpec.describe RunCheckJob do
  let(:site) { create(:site) }
  let(:audit) { create(:audit, site: site) }
  let(:check) { audit.checks.first }
  let(:retryable_error) { Check::RETRYABLE_ERRORS.first }

  describe '#perform' do
    it 'runs the given check' do
      allow(check).to receive(:run)
      allow(audit).to receive(:update_from_checks)
      allow(audit).to receive(:next_check).and_return(nil)

      described_class.new.perform(check)

      expect(check).to have_received(:run)
    end

    it 'updates audit status after running check' do
      allow(check).to receive(:run)
      allow(audit).to receive(:update_from_checks)
      allow(audit).to receive(:next_check).and_return(nil)

      described_class.new.perform(check)

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

    context 'when no more checks remain' do
      it 'does not reschedule' do
        job = described_class.new
        allow(check).to receive(:run)
        allow(audit).to receive(:update_from_checks)
        allow(audit).to receive(:next_check).and_return(nil)

        allow(described_class).to receive(:set)

        job.perform(check)

        expect(described_class).not_to have_received(:set)
      end
    end
  end

  describe '#wait_until' do
    let(:job) { described_class.new }

    before { job.instance_variable_set(:@check, check) }

    context 'when there are failed retryable checks' do
      it 'returns earliest retry time' do
        audit.checks.first.update!(status: :failed, retry_at: 1.minute.from_now, error_type: retryable_error)
        audit.checks.where.not(id: audit.checks.first.id).update_all(status: :passed)
        retry_at = audit.checks.first.reload.retry_at

        expect(job.send(:wait_until)).to eq(retry_at)
      end
    end

    context 'when there are pending checks with run_at' do
      it 'returns earliest run_at time' do
        run_at = 30.minutes.from_now
        audit.checks.first.update!(status: :pending, run_at: run_at)
        audit.checks.where.not(id: audit.checks.first.id).update_all(status: :passed)

        expect(job.send(:wait_until)).to be_within(1.second).of(run_at)
      end
    end

    context 'when there are no scheduled checks' do
      it 'returns 1 second from now' do
        audit.checks.update_all(status: :passed)

        expect(job.send(:wait_until)).to be_within(1.second).of(1.second.from_now)
      end
    end
  end
end
