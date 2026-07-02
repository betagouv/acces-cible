class ProcessBatchSitesCreationJob < ApplicationJob
  include ActiveJob::Continuable

  def perform(sites_data, team_id, tag_ids, user_id)
    team = Team.find(team_id)
    user = User.find(user_id)
    site_batch_creation = SiteBatchCreationService.new(team:, tag_ids:, user:)

    step :process_sites do |step|
      start_index = step.cursor || 0

      sites_data.drop(start_index).each_with_index do |site_data, index|
        site_batch_creation.process(site_data)
        step.advance! from: start_index + index
      end
    end

    step :refresh_sites_index do
      Turbo::StreamsChannel.broadcast_refresh_later_to [team, :sites]
    end
  end
end
