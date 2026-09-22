class ProcessSiteUploadJob < ApplicationJob
  def perform(sites_data, team_id, user_id, audit_batch_id)
    sites_data.in_groups_of(100, false) do |group|
      ProcessAuditBatchCreationJob.perform_later(group, team_id, user_id, audit_batch_id)
    end
  end
end
