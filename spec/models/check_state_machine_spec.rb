# frozen_string_literal: true

require "rails_helper"

describe CheckStateMachine do
  let(:machine) { check.state_machine }
  let(:check) { create(:check, :reachable) }

  context "when moving to ready" do
    context "when the requirements aren't met" do
      before do
        allow(check).to receive(:all_requirements_met?).and_return false
      end

      it "raises an error" do
        expect { machine.transition_to!(:ready) }
          .to raise_error Statesman::GuardFailedError
      end
    end
  end

  context "when moving to completed" do
    let(:check) { create(:check, :reachable, :running) }

    it "calls back to the audit" do
      expect(check.audit).to receive(:after_check_completed).with(check)

      check.transition_to!(:completed)
    end
  end

  context "when moving to failed" do
    let(:check) { create(:check, :reachable, :running) }

    it "tells the audit to look at dependent jobs" do
      expect(check.audit).to receive(:abort_dependent_checks!).with(check)

      check.transition_to!(:failed)
    end
  end

  context "when moving to errored" do
    let(:check) { create(:check, :reachable, :running) }

    it "tells the audit to look at dependent jobs" do
      expect(check.audit).to receive(:abort_dependent_checks!).with(check)

      check.transition_to!(:errored)
    end
  end
end
