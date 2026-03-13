require "rails_helper"

RSpec.describe ErrorHelper do
  describe "#report" do
    let(:helper) { described_class }
    let(:exception) { StandardError.new("Test error") }
    let(:message) { "Test message" }
    let(:scope) { instance_double(Sentry::Scope) }

    before do
      allow(Sentry).to receive(:initialized?).and_return(true)
      allow(Sentry).to receive(:with_scope).and_yield(scope)
      allow(Sentry).to receive(:capture_exception)
      allow(Sentry).to receive(:capture_message)
      allow(Rails.logger).to receive(:warn)
    end

    context "when Sentry is not initialized" do
      before { allow(Sentry).to receive(:initialized?).and_return(false) }

      it "returns early without doing anything" do
        expect(Sentry).not_to receive(:with_scope)
        expect(Sentry).not_to receive(:capture_exception)

        helper.report(exception:)
      end
    end

    context "when neither exception nor message is provided" do
      it "raises ArgumentError" do
        expect { helper.report }.to raise_error(ArgumentError, "Please provide either an exception or error message.")
      end
    end

    context "when exception is provided" do
      it "captures the exception via Sentry" do
        expect(Sentry).to receive(:capture_exception).with(exception)

        helper.report(exception:)
      end

      it "calls the block with scope when provided" do
        expect(scope).to receive(:set_context).with("test", { key: "value" })

        helper.report(exception:) do |s|
          s.set_context("test", { key: "value" })
        end
      end
    end

    context "when message is provided" do
      it "captures the message via Sentry" do
        expect(Sentry).to receive(:capture_message).with(message)

        helper.report(message:)
      end

      it "calls the block with scope when provided" do
        expect(scope).to receive(:set_context).with("user", { id: 123 })

        helper.report(message:) do |s|
          s.set_context("user", { id: 123 })
        end
      end
    end

    context "when both exception and message are provided" do
      it "reports both exception and message" do
        expect(Sentry).to receive(:capture_exception).with(exception)
        expect(Sentry).to receive(:capture_message)

        helper.report(exception:, message:)
      end
    end

    context "with scope configuration" do
      it "works without a block" do
        expect(Sentry).to receive(:capture_exception).with(exception)

        helper.report(exception:)
      end

      it "allows setting multiple contexts in the block" do
        expect(scope).to receive(:set_context).with("user", { id: 123 })
        expect(scope).to receive(:set_context).with("request", { path: "/test" })

        helper.report(exception:) do |s|
          s.set_context("user", { id: 123 })
          s.set_context("request", { path: "/test" })
        end
      end
    end

    context "when Rails.event.notify is available" do
      before do
        rails_event = instance_double(Object)
        Rails.define_singleton_method(:event) { rails_event }
        allow(rails_event).to receive(:respond_to?).with(:notify).and_return(true)
      end

      after do
        Rails.singleton_class.remove_method(:event) if Rails.respond_to?(:event)
      end

      it "shows deprecation warning" do
        expect(Rails.logger).to receive(:warn).with(
          "DEPRECATION WARNING: ErrorHelper#report is deprecated. Use Rails.event.notify instead."
        )

        helper.report(exception:)
      end
    end

    context "when Rails.event.notify is not available" do
      it "does not show deprecation warning" do
        expect(Rails.logger).not_to receive(:warn)

        helper.report(exception:)
      end
    end
  end
end
