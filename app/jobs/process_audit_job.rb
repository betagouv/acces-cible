class ProcessAuditJob < ApplicationJob
  limits_concurrency to: 1, key: ->(audit) { audit }

  attr_reader :audit
  delegate :checks, to: :audit

  def perform(audit)
    @audit = audit

    if (check = next_check)
      check.run
      audit.derive_status_from_checks
      reschedule
    else
      audit.finalize!
    end
  end

  private

  def next_check
    checks.pending.first ||
    checks.to_retry.first ||
    unblocked_checks.first
  end

  def unblocked_checks
    checks.blocked.reject(&:blocked?)
  end

  def reschedule
    next_retry_at = checks.failed.retryable.minimum(:retry_at)
    next_run_at = checks.pending.minimum(:run_at)

    wait_until = [next_retry_at, next_run_at].compact.min || 1.minute.from_now
    self.class.set(wait_until:, group: "audit_#{audit.id}").perform_later(audit)
  end
end
