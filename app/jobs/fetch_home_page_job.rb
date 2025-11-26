class FetchHomePageJob < ApplicationJob
  queue_as :slow

  def perform(audit)
    begin
      Browser
        .get(audit.url)
        .then { |response| audit.update_home_page!(response) }
    ensure
      ProcessAuditJob.perform_later(audit)
    end
  end
end
