require 'rails_helper'

RSpec.describe RunCheckJob do
  let(:check) { create(:check, :accessibility_mention, :ready) }

  context "when the check goes well" do
    before do
      # Sure, the any_instance_of is sad but there is no other way:
      # since ActiveJob deserializes models with GlobalID, mocking the
      # object here will have no effect when ActiveJob reinstantiates
      # a model on its side.
      allow_any_instance_of(Check) # rubocop:disable RSpec/AnyInstance
        .to receive(:run!).and_return :test_success
    end

    it "transitions the check to completed" do
      perform_enqueued_jobs do
        expect { described_class.perform_later(check) }
          .to change(check, :current_state)
                .from("ready")
                .to("completed")
      end
    end
  end

  context "when check#run! raises an error" do
    before do
      error = Ferrum::TimeoutError.new("Timed out waiting for response")
      app_path = Rails.root.to_s
      error.set_backtrace([
        "#{app_path}/app/models/check.rb:124:in `analyze!'",
        "#{app_path}/app/models/check.rb:89:in `run!'",
        "#{app_path}/app/jobs/run_check_job.rb:12:in `perform'",
        "/lib/ruby/gems/3.4.0/gems/ferrum-0.17.1/lib/ferrum/browser.rb:245:in `command'",
        "/lib/ruby/gems/3.4.0/gems/ferrum-0.17.1/lib/ferrum/page.rb:134:in `evaluate'",
        "/lib/ruby/gems/3.4.0/gems/activejob-8.1.0/lib/active_job/execution.rb:58:in `block in perform_now'",
        "/lib/ruby/gems/3.4.0/gems/activejob-8.1.0/lib/active_job/execution.rb:47:in `perform_now'",
        "/lib/ruby/gems/3.4.0/gems/solid_queue-1.2.1/lib/solid_queue/job.rb:89:in `perform'",
        "/lib/ruby/gems/3.4.0/gems/solid_queue-1.2.1/lib/solid_queue/worker.rb:78:in `block in work'",
        "/lib/ruby/3.4.0/timeout.rb:123:in `timeout'",
        "/lib/ruby/3.4.0/net/http.rb:1458:in `request'",
        "/lib/ruby/3.4.0/net/http.rb:1299:in `get'",
        "bin/rails:4:in `<main>'"
      ])

      allow_any_instance_of(check.class) # rubocop:disable RSpec/AnyInstance
        .to receive(:analyze!).and_raise error
    end

    it "transitions the check to errored" do
      perform_enqueued_jobs do
        expect { described_class.perform_later(check) }
          .to change(check, :current_state)
                .from("ready")
                .to("errored")
      end
    end

    it "stores the error in the transition metadata" do
      perform_enqueued_jobs do
        described_class.perform_later(check)
      end

      expect(check.error)
        .to include(
          error_type: "Ferrum::TimeoutError",
          message: /Timed out/
        )
    end

    it "keeps only app-relative paths in the backtrace" do
      perform_enqueued_jobs do
        described_class.perform_later(check)
      end

      backtrace = check.error[:backtrace]
      expect(backtrace).to be_present
      expect(backtrace).to all(match(/^app\//)) # Should only contain app paths after cleaning
    end
  end
end
