# frozen_string_literal: true

require "rails_helper"

describe CheckStateMachine do
  let(:machine) { check.state_machine }
  let(:check) { create(:reachable_check) }

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
    let(:check) { create(:reachable_check, :running) }

    it "calls back to the audit" do
      expect(check.audit).to receive(:after_check_completed).with(check)

      check.transition_to!(:completed)
    end
  end
end
