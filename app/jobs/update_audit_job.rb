class UpdateAuditJob < ApplicationJob
  def perform(audit)
    audit.finalize!
  end
end
