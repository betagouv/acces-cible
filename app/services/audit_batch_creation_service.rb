class AuditBatchCreationService
  def initialize(team:, user:, audit_batch:)
    @team = team
    @user = user
    @audit_batch = audit_batch
  end

  def process(site_data)
    tag_ids = site_tag_ids(site_data)
    site = @team.sites.find_by(normalized_url: Link.url_without_scheme_and_www(site_data["url"]))

    if site
      update_site(site, site_data, tag_ids)
      site.audit!(user: @user, audit_batch: @audit_batch)
    else
      Site.create!(url: site_data["url"], team: @team, tag_ids:).audit!(user: @user, audit_batch: @audit_batch)
    end
  end

  private

  def update_site(site, site_data, site_tag_ids)
    site.tag_ids = site_tag_ids.union(site.tag_ids)
    site.save!
  end

  def site_tag_ids(site_data)
    tag_ids_from_names(site_data["tag_names"] || []).uniq
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
