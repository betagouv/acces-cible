# Grabs an audit and tries to queue all the checks that can be
# readied, or unblocked. The idea is to re-queue this whenever a check
# finishes to gradually move blocked checks to ready, otherwise it is
# harmless.
class ProcessAuditJob < ApplicationJob
  def perform(audit)
    audit
      .checks
      .remaining
      .filter { |check| Statesman::Machine.retry_conflicts { check.transition_to(:ready) } }
      .each { |check| RunCheckJob.set(group: "check_#{check.id}").perform_later(check) }
  end
end
