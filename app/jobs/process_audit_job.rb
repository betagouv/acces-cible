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
      .each { |check| enqueue_check(check) }
  end

  private

  def enqueue_check(check)
    options = { group: "check_#{check.id}" }
    options[:queue] = :chrome if check.is_a?(Checks::RunAxeOnHomepage)

    RunCheckJob.set(options).perform_later(check)
  end
end
