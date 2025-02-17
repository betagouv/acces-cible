class UpdateAuditStatusJob < ApplicationJob
  def perform
    audit = params.values_at(:audit)
    audit.derive_status_from_checks
  end
end
