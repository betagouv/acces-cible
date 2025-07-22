require 'rails_helper'

RSpec.describe ProcessAuditJob do
  let(:site) { create(:site) }
  let(:audit) { create(:audit, site: site) }

  describe '#perform' do
    context 'when there are checks to run' do
      let(:job) { described_class.new }

      it 'runs the next check and reschedules' do
        check = audit.checks.first
        allow(job).to receive(:next_check).and_return(check)
        allow(check).to receive(:run).and_return(true)

        job_class_double = class_double(described_class)
        allow(described_class).to receive(:set).with(wait_until: kind_of(Time), group: "audit_#{audit.id}").and_return(job_class_double)
        allow(job_class_double).to receive(:perform_later)

        job.perform(audit)
        expect(check).to have_received(:run)
      end

      it 'reschedules even when check returns false' do
        check = audit.checks.first
        allow(job).to receive(:next_check).and_return(check)
        allow(check).to receive(:run).and_return(false)

        job_class_double = class_double(described_class)
        allow(described_class).to receive(:set).with(wait_until: kind_of(Time), group: "audit_#{audit.id}").and_return(job_class_double)
        allow(job_class_double).to receive(:perform_later)

        job.perform(audit)
        expect(job_class_double).to have_received(:perform_later)
      end
    end

    context 'when no checks are available' do
      let(:audit) { create(:audit, site: site) }

      before do
        audit.checks.update_all(status: :passed)
      end

      it 'finalizes the audit' do
        expect(audit).to receive(:finalize!)

        described_class.new.perform(audit)
      end
    end
  end

  describe '#next_check' do
    let(:job) { described_class.new }

    before { job.instance_variable_set(:@audit, audit) }

    it 'returns pending check first' do
      pending_check = audit.checks.first
      pending_check.update!(status: :pending)

      expect(job.send(:next_check)).to eq(pending_check)
    end

    it 'returns retryable check if no pending' do
      audit.checks.update_all(status: :passed)
      retryable_check = audit.checks.first
      retryable_check.update!(status: :failed, retry_at: 1.minute.ago)

      expect(job.send(:next_check)).to eq(retryable_check)
    end

    it 'returns unblocked check if no pending or retryable' do
      audit.checks.update_all(status: :blocked)
      blocked_check = audit.checks.first # Use first check which has lowest priority
      blocked_check.update!(status: :blocked)
      allow(blocked_check).to receive(:blocked?).and_return(false)

      expect(job.send(:next_check)).to eq(blocked_check)
    end
  end

  describe '#reschedule' do
    let(:job) { described_class.new }

    before { job.instance_variable_set(:@audit, audit) }

    context 'when there are failed retryable checks' do
      it 'schedules job to run at earliest retry time' do
        retry_time = 5.minutes.from_now.round
        audit.checks.first.update!(status: :failed, retry_at: retry_time)

        job_class_double = class_double(described_class)
        allow(described_class).to receive(:set).with(wait_until: retry_time, group: "audit_#{audit.id}").and_return(job_class_double)
        allow(job_class_double).to receive(:perform_later)

        job.send(:reschedule)
        expect(described_class).to have_received(:set).with(wait_until: retry_time, group: "audit_#{audit.id}")
        expect(job_class_double).to have_received(:perform_later).with(audit)
      end
    end

    context 'when there are no failed retryable checks' do
      it 'schedules job to run in 5 minutes' do
        audit.checks.update_all(status: :passed)

        job_class_double = class_double(described_class)
        allow(described_class).to receive(:set).with(wait_until: kind_of(Time), group: "audit_#{audit.id}").and_return(job_class_double)
        allow(job_class_double).to receive(:perform_later)

        job.send(:reschedule)
        expect(described_class).to have_received(:set).with(wait_until: kind_of(Time), group: "audit_#{audit.id}")
        expect(job_class_double).to have_received(:perform_later).with(audit)
      end
    end
  end
end
