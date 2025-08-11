class RunCheckJob < ApplicationJob
  attr_reader :check
  delegate :audit, to: :check
  delegate :checks, to: :audit, prefix: true

  def perform(check)
    @check = check
    check.run
    audit.update_from_checks

    if (next_schedulable_check = audit.next_check)
      self.class.set(wait_until:).perform_later(next_schedulable_check)
    end
  end

  private

  def wait_until
    next_retry_at = audit_checks.failed.retryable.minimum(:retry_at)
    next_run_at = audit_checks.pending.minimum(:run_at)
    [next_retry_at, next_run_at].compact.min || 1.second.from_now
  end
end
