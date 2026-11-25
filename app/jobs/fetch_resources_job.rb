class FetchResourcesJob < ApplicationJob
  queue_as :slow

  # sometimes the underlying Chrome process is [defunct], as show when
  # inspecting the jobs container with `ps -ef`: it hasn't been killed
  # properly so SolidQueue has to wait and timeout the job on
  # Ferrum::ProcessTimeoutError. Failing the job seems to get rid of
  # the defunct process, so maybe killing the corresponding thread
  # (within the process) is enough to clear up the process.
  retry_on Ferrum::ProcessTimeoutError

  def perform(audit)
    FetchHomePageService.new(audit)
    return audit.abort_dependent_checks!(audit.reachable) unless audit.home_page_snapshot.auditable?

    FindAccessibilityPageService.new(audit)
  ensure
    ProcessAuditJob.perform_later(audit)
  end
end
