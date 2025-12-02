class FetchResourcesJob < ApplicationJob
  queue_as :slow

  rescue_from(Ferrum::StatusError, Ferrum::TimeoutError) do |exception|
    Rails.logger.debug("Failed to fetch SOME home page HTML because: #{exception}")
  end

  def perform(audit)
    FetchHomePageService.call(audit)
    FindAccessibilityPageService.call(audit)
  ensure
    ProcessAuditJob.perform_later(audit)
  end
end
