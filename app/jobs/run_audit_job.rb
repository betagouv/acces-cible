class RunAuditJob < ApplicationJob
  def perform(audit)
    audit.update!(scheduled: false)
    audit.all_checks.each { |check| check.schedule! }
  end
end
