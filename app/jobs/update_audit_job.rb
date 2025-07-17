class UpdateAuditJob < ApplicationJob
  limits_concurrency key: ->(audit) { audit }

  def perform(audit)
    audit.derive_status_from_checks
    audit.set_checked_at
    audit.site.set_current_audit!
  end
end
