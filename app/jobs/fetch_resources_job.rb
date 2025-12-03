class FetchResourcesJob < ApplicationJob
  queue_as :slow

  rescue_from(Ferrum::StatusError, Ferrum::TimeoutError) do |exception|
    Rails.logger.debug("Failed to fetch SOME home page HTML because: #{exception}")
  end

  # sometimes the underlying Chrome process is [defunct], as show when
  # inspecting the jobs container with `ps -ef`: it hasn't been killed
  # properly so SolidQueue has to wait and timeout the job on
  # Ferrum::ProcessTimeoutError. Failing the job seems to get rid of
  # the defunct process, so maybe killing the corresponding thread
  # (within the process) is enough to clear up the process.
  retry_on Ferrum::ProcessTimeoutError

  def perform(audit)
    FetchHomePageService.call(audit)
    FindAccessibilityPageService.call(audit)
  ensure
    ProcessAuditJob.perform_later(audit)
  end
end
