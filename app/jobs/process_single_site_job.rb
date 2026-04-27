class ProcessSingleSiteJob < ApplicationJob
  def perform(site_data, team_id, tag_ids)
    team = Team.find(team_id)
    tag_names = site_data["tag_names"] || []
    tag_ids = tag_ids + tag_ids_from_names(team, tag_names)
    site = team.sites.find_by_url(url: site_data["url"])

    if site
      update_site(site, site_data, tag_ids)
    else
      Site.create!(url: site_data["url"], team:, name: site_data["name"], tag_ids: tag_ids.uniq)
    end
  end

  private

  def update_site(site, site_data, tag_ids)
    site.tag_ids = tag_ids.union(site.tag_ids)
    site.name = site_data["name"] if site_data["name"].present? && site.name.blank?
    site.save!
    site.audit!
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
