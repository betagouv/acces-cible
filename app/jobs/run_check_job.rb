class RunCheckJob < ApplicationJob
  def perform
    check = params.values_at(:check)
    return unless check.runnable?

    check.run

    UpdateAuditStatusJob.with(check.audit).perform_later
    check.audit.update(checked_at: Time.zone.now)
  end
end
