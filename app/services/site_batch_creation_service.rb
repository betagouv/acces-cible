class SiteBatchCreationService
  def initialize(team:, tag_ids:)
    @team = team
    @tag_ids = tag_ids
  end

  def process(site_data)
    site_tag_ids = @tag_ids + tag_ids_from_names(site_data["tag_names"] || [])
    site_tag_ids = normalized_tag_ids(site_tag_ids)
    site = @team.sites.find_by(url: site_data["url"])

    if site
      update_site(site, site_data, site_tag_ids)
      site.audit!
    else
      Site.create!(url: site_data["url"], team: @team, name: site_data["name"], tag_ids: site_tag_ids.uniq).audit!
    end
  end

  private

  def update_site(site, site_data, site_tag_ids)
    site.tag_ids = site_tag_ids.union(site.tag_ids)
    site.name = site_data["name"] if site_data["name"].present? && site.name.blank?
    site.save!
  end

  def normalized_tag_ids(tag_ids)
    tag_ids.compact_blank.map(&:to_i).uniq
  end

  def tag_ids_from_names(tag_names)
    tag_names.map { |name| find_or_create_tag(name).id }
  end

  def find_or_create_tag(name)
    @team.tags.find_or_create_by!(name:)
  rescue ActiveRecord::RecordNotUnique
    @team.tags.find_by!(name:)
  end
end
