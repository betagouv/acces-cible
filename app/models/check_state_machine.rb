# frozen_string_literal: true

class CheckStateMachine
  include Statesman::Machine

  state :pending, initial: true
  state :ready
  state :blocked
  state :running
  state :failed
  state :completed

  transition from: :pending, to: [:ready, :blocked]
  transition from: :ready,   to: [:running]
  transition from: :running, to: [:failed, :completed]
  transition from: :blocked, to: [:ready]

  guard_transition(to: :ready) do |check|
    check.all_requirements_met?
  end

  after_transition(to: :completed) do |check|
    check.audit.after_check_completed(check)
  end
end
