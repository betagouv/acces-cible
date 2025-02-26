class UpdateAuditStatusJob < ApplicationJob
  def perform(audit)
    audit.derive_status_from_checks
  end
end
