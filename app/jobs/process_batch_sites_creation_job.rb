class ProcessBatchSitesCreationJob < ApplicationJob
  include ActiveJob::Continuable

  def perform(sites_data, team_id, tag_ids)
    team = Team.find(team_id)

    step :process_sites do |step|
      start_index = step.cursor || 0

      sites_data.drop(start_index).each_with_index do |site_data, index|
        process_site(site_data, team, tag_ids)
        step.advance! from: start_index + index
      end
    end

    step :refresh_sites_index do
      Turbo::StreamsChannel.broadcast_refresh_later_to [team, :sites]
    end
  end

  private

  def process_site(site_data, team, tag_ids)
    tag_names = site_data["tag_names"] || []
    tag_ids = tag_ids + tag_ids_from_names(team, tag_names)
    site = team.sites.find_by_url(url: site_data["url"])

    if site
      update_site(site, site_data, tag_ids)
      site.audit!
    else
      Site.create!(url: site_data["url"], team:, name: site_data["name"], tag_ids: tag_ids.uniq)
    end
  end

  def update_site(site, site_data, tag_ids)
    site.tag_ids = tag_ids.union(site.tag_ids)
    site.name = site_data["name"] if site_data["name"].present? && site.name.blank?
    site.save!
  end

  def tag_ids_from_names(team, tag_names)
    tag_names.map { |name| find_or_create_tag(team, name).id }
  end

  def find_or_create_tag(team, name)
    team.tags.find_or_create_by!(name:)
  rescue ActiveRecord::RecordNotUnique
    team.tags.find_by!(name:)
  end
end
