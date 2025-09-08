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

  context "when the check does not go well" do
    before do
      allow_any_instance_of(check.class) # rubocop:disable RSpec/AnyInstance
        .to receive(:analyze!).and_raise Ferrum::TimeoutError.new("Test error")
    end

    it "transitions the check to failed" do
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
          klass: "Ferrum::TimeoutError",
          message: /Timed out/
        )
    end

    it "cleans the backtrace before storing the exception" do
      perform_enqueued_jobs do
        described_class.perform_later(check)
      end

      backtrace = check.error[:backtrace]
      expect(backtrace).to be_present
      expect(backtrace).to all(match(/^app\//)) # Should only contain app paths after cleaning
    end
  end
end
