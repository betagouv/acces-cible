class UpdateAuditJob < ApplicationJob
  def perform(audit)
    Audit.transaction do
      audit.derive_status_from_checks
      audit.set_checked_at
    end
  end
end
