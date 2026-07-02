class ProcessSiteUploadJob < ApplicationJob
  def perform(sites_data, team_id, tag_ids, user_id)
    sites_data.in_groups_of(100, false) do |group|
      ProcessBatchSitesCreationJob.perform_later(group, team_id, tag_ids, user_id)
    end
  end
end
