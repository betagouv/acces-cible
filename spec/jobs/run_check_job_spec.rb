require 'rails_helper'

RSpec.describe RunCheckJob do
  let(:check) { create(:check, :accessibility_mention, :ready) }

  context "when check.run! doesn't raise" do
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

  context "when check.run! raises a PermanentError (DNS error)" do
    before do
      allow_any_instance_of(check.class) # rubocop:disable RSpec/AnyInstance
        .to receive(:analyze!).and_raise Checks::Reachable::DnsResolutionError.new("https://test.com")
    end

    it "transitions the check to failed immediately" do
      perform_enqueued_jobs do
        expect { described_class.perform_later(check) }
          .to change(check, :current_state)
                .from("ready")
                .to("failed")
      end
    end

    it "stores the original error in the transition metadata" do
      perform_enqueued_jobs do
        described_class.perform_later(check)
      end

      expect(check.error)
        .to include(
          "json_class" => "Checks::Reachable::DnsResolutionError",
          "m" => "DNS resolution failed for https://test.com"
        )
    end
  end

  context "when check.run! raises a PermanentError (crawler error)" do
    before do
      allow_any_instance_of(check.class) # rubocop:disable RSpec/AnyInstance
        .to receive(:analyze!) do
          original_error = StandardError.new("Original cause error")
          raise Check::NonRetryableError, "Wrapper error", cause: original_error
        end
    end

    it "transitions the check to failed immediately" do
      perform_enqueued_jobs do
        expect { described_class.perform_later(check) }
          .to change(check, :current_state)
                .from("ready")
                .to("failed")
      end
    end

    it "stores the original cause error in the transition metadata" do
      perform_enqueued_jobs do
        described_class.perform_later(check)
      end

      expect(check.error)
        .to include(
          "json_class" => "Check::NonRetryableError",
          "m" => "Wrapper error"
        )
    end
  end

  context "when check.run! raises a retryable error" do
    before do
      allow_any_instance_of(check.class) # rubocop:disable RSpec/AnyInstance
        .to receive(:analyze!).and_raise Ferrum::TimeoutError.new("Test error")
    end

    it "transitions the check to failed after retries" do
      perform_enqueued_jobs do
        expect { described_class.perform_later(check) }
          .to change(check, :current_state)
                .from("ready")
                .to("failed")
      end
    end

    it "stores the error in the transition metadata" do
      perform_enqueued_jobs do
        described_class.perform_later(check)
      end

      expect(check.error)
        .to include(
          "json_class" => "Ferrum::TimeoutError",
          "m" => /Timed out/
        )
    end
  end
end
