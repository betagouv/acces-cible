class RunAuditJob < ApplicationJob
  def perform(audit)
    audit.update!(scheduled: false)
    audit.checks.prioritized.each_with_index do |check, index|
      check.update!(run_at: index.minutes.from_now)
      check.schedule!
    end
  end
end
