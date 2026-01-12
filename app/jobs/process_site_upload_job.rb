class ProcessSiteUploadJob < ApplicationJob
  queue_as :default

  def perform(sites_data, team_id, tag_ids)
    site_jobs = sites_data.map do |site_data|
      ProcessSingleSiteJob.new(site_data, team_id, tag_ids)
    end

    ActiveJob.perform_all_later(site_jobs) if site_jobs.any?
  end
end
