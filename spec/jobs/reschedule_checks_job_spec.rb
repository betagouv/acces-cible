require "rails_helper"

RSpec.describe RescheduleChecksJob do
  describe "#perform" do
    subject(:job) { described_class.new }

    let!(:failed_check_retriable) { create(:check, status: :failed, retry_count: 1, retry_at: 1.hour.ago, scheduled: false) }
    let!(:failed_check_max_retries) { create(:check, status: :failed, retry_count: 3, retry_at: 1.hour.ago, scheduled: false) }
    let!(:blocked_check_retriable) { create(:check, status: :blocked, retry_count: 0, retry_at: 1.hour.ago, scheduled: false) }
    let!(:future_retry_check) { create(:check, status: :failed, retry_count: 1, retry_at: 1.hour.from_now, scheduled: false) }
    let!(:pending_check) { create(:check, status: :pending, run_at: 1.hour.ago, scheduled: false) }

    it "reschedules retriable failed and blocked checks with past retry_at" do
      # Run the job without stubbing to test actual integration
      job.perform

      # Retry-eligible checks should be rescheduled
      expect(failed_check_retriable.reload.status).to eq("pending")
      expect(failed_check_retriable.reload.scheduled).to be true

      expect(blocked_check_retriable.reload.status).to eq("pending")
      expect(blocked_check_retriable.reload.scheduled).to be true

      # These checks should not be changed
      expect(failed_check_max_retries.reload.status).to eq("failed")
      expect(failed_check_max_retries.reload.scheduled).to be false

      expect(future_retry_check.reload.status).to eq("failed")
      expect(future_retry_check.reload.scheduled).to be false

      expect(pending_check.reload.status).to eq("pending")
      expect(pending_check.reload.scheduled).to be false
    end

    it "uses the to_retry scope to find checks" do
      allow(Check).to receive(:to_retry).and_return(Check.none)
      job.perform
      expect(Check).to have_received(:to_retry)
    end
  end
end
