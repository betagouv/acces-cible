class ProcessAuditJob < ApplicationJob
  limits_concurrency to: 1, key: ->(audit) { audit }

  def perform(audit)
    if (check = audit.next_check)
      RunCheckJob.perform_later(check)
    end
  end
end
