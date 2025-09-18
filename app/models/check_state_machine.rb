# frozen_string_literal: true

class CheckStateMachine
  include Statesman::Machine

  state :pending, initial: true
  state :ready
  state :blocked
  state :running
  state :errored
  state :failed
  state :completed
  state :aborted

  transition from: :pending, to: [:ready, :blocked, :aborted]
  transition from: :ready,   to: [:running]
  transition from: :running, to: [:errored, :failed, :completed]
  transition from: :blocked, to: [:ready, :aborted]
  transition from: :errored, to: [:failed, :completed]

  guard_transition(to: :ready) do |check|
    check.all_requirements_met?
  end

  after_transition(to: :errored) do |check|
    check.audit.abort_dependent_checks!(check)
  end

  after_transition(to: :failed) do |check|
    check.audit.abort_dependent_checks!(check)
  end

  after_transition(to: :completed) do |check|
    check.audit.after_check_completed(check)
  end
end
