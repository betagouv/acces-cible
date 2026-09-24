class ProcessAuditBatchCreationJob < ApplicationJob
  include ActiveJob::Continuable

  def perform(sites_data, team_id, user_id, audit_batch_id)
    team = Team.find(team_id)
    user = team.users.find(user_id)

    return unless user.present?

    audit_batch = user.audit_batches.find(audit_batch_id)
    audit_batch_creation = AuditBatchCreationService.new(team:, user:, audit_batch:)

    step :process_sites do |step|
      start_index = step.cursor || 0

      sites_data.drop(start_index).each_with_index do |site_data, index|
        audit_batch_creation.process(site_data)
        step.advance! from: start_index + index
      end
    end

    step :refresh_sites_index do
      Turbo::StreamsChannel.broadcast_refresh_later_to [team, :sites]
    end

    step :refresh_audit_batch do
      Turbo::StreamsChannel.broadcast_refresh_later_to audit_batch
    end
  end
end
