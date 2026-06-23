class FetchResourcesJob < ApplicationJob
  include ActiveJob::Continuable

  queue_as :slow

  rescue_from(Ferrum::StatusError, Ferrum::TimeoutError) do |exception|
    Rails.logger.debug("Failed to fetch SOME home page HTML because: #{exception}")
  end

  def perform(audit)
    step :start do
      Rails.logger.info("Started for #{audit.url}")
    end

    step :fetch_home_page do
      FetchHomePageService.call(audit)
    end

    step :find_accessibility_page do
      FindAccessibilityPageService.call(audit)
    end

  ensure
    ProcessAuditJob.perform_later(audit)
  end
end
