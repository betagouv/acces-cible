class RunCheckJob < ApplicationJob
  def perform(check)
    return unless check.due?

    check.run

    UpdateAuditJob.perform_later(check.audit)
  end
end
