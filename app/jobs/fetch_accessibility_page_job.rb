class FetchAccessibilityPageJob < ApplicationJob
  queue_as :slow

  rescue_from(Ferrum::StatusError, Ferrum::TimeoutError) do |exception|
    Rails.logger.debug("Failed to fetch accessibility page HTML because: #{exception}")
  end

  def perform(audit)
    page = FindAccessibilityPageService.new(audit).call

    if page
      audit.update_accessibility_page!(page.url, page.html)
    end
  ensure
    ProcessAuditJob.perform_later(audit)
  end
end
