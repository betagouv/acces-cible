require 'rails_helper'

RSpec.describe ApplicationJob do
  let(:job_instance) do
    job = described_class.new
    job.job_id = "test-job-id"
    job.queue_name = "background"
    job.arguments = ["test", { arg2: "value" }]
    job
  end

  describe "#monitor_with_sentry" do
    # We need basic doubles because Sentry is not loaded in test environment
    # rubocop:disable RSpec/VerifiedDoubles
    let(:transaction_double) { double("Transaction", set_data: nil, finish: nil) }
    let(:sentry_double) { double("Sentry") }
    # rubocop:enable RSpec/VerifiedDoubles

    before do
      stub_const("Sentry", sentry_double)
      allow(sentry_double).to receive(:start_transaction).and_return(transaction_double)
      allow(sentry_double).to receive(:capture_exception)
    end

    context "when job performs successfully" do
      subject(:perform_now) { job_instance.send(:monitor_with_sentry) { "success" } }

      it "creates a Sentry transaction with queue name and arguments" do
        expect(transaction_double).to receive(:set_data).with(:queue, "background")
        expect(transaction_double).to receive(:set_data).with(:arguments, ["test", { arg2: "value" }])
        expect(sentry_double).to receive(:start_transaction).with(
          op: "queue.solid_queue",
          name: "ApplicationJob"
        )
        expect(transaction_double).to receive(:finish)

        job_instance.send(:monitor_with_sentry) { "success" }
      end
    end

    context "when the job raises" do
      subject(:perform_now) { job_instance.send(:monitor_with_sentry) { raise error } }

      let(:error) { StandardError.new("Test error") }

      it "creates a Sentry transaction, captures and reraises the exception" do
        expect(sentry_double).to receive(:start_transaction).with(
          op: "queue.solid_queue",
          name: "ApplicationJob"
        )
        expect(transaction_double).to receive(:finish)
        expect(sentry_double).to receive(:capture_exception).with(
          error,
          extra: {
            job_class: "ApplicationJob",
            arguments: ["test", { arg2: "value" }],
            queue: "background"
          }
        )

        expect { perform_now }.to raise_error(StandardError, "Test error")
      end
    end
  end
end
