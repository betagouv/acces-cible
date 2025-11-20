class ProcessSingleSiteJob < ApplicationJob
  queue_as :default

  def perform(site_data, team_id, tag_ids)
    team = Team.find(team_id)

    url = site_data["url"]
    name = site_data["name"]
    tag_names = site_data["tag_names"] || []

    row_tag_ids = tag_names.map { |tag_name| team.tags.find_or_create_by(name: tag_name).id }
    combined_tag_ids = (tag_ids + row_tag_ids).uniq

    site = team.sites.find_by_url(url: url)

    if site
      site.tag_ids = combined_tag_ids.union(site.tag_ids)
      site.name = name if name.present? && site.name.blank?
      site.save!
      site.audit!
    else
      Site.create!(url: url, team: team, name: name, tag_ids: combined_tag_ids)
    end
  end
end
