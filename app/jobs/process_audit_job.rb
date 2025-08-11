# Grabs an audit and tries to queue all the checks that can be
# readied, or unblocked. The idea is to re-queue this whenever a check
# finishes to gradually move blocked checks to ready, otherwise it is
# harmless.
class ProcessAuditJob < ApplicationJob
  def perform(audit)
    ready_check_jobs = audit
                       .checks
                       .remaining
                       .filter { |check| check.transition_to(:ready) }
                       .map { |check| RunCheckJob.new(check) }

    ActiveJob.perform_all_later(ready_check_jobs)
  end
end
