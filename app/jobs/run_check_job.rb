class RunCheckJob < ApplicationJob
  def perform(check)
    return unless check.due?

    check.run

    check.audit.update(checked_at: Time.zone.now)

    UpdateAuditStatusJob.perform_later(check.audit)
  end
end
