class RunAuditJob < ApplicationJob
  def perform(audit)
    audit.all_checks.each { |check| check.schedule! }
  end
end
