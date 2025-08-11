class RunCheckJob < ApplicationJob
  def perform(check)
    audit = check.audit

    check.run
    audit.update_from_checks

    if (next_check = audit.next_check)
      wait_until = next_check.retry_at || next_check.run_at || 1.second.from_now
      self.class.set(wait_until:).perform_later(next_check)
    end
  end
end
