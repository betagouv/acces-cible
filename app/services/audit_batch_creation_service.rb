class AuditBatchCreationService
  def initialize(team:, tag_ids:, user:, audit_batch: nil)
    @team = team
    @tag_ids = tag_ids
    @user = user
    @audit_batch = audit_batch
  end

  def process(site_data)
    site = find_site(site_data["url"]) || @team.sites.new(url: site_data["url"])
    site.tag_ids = site_tag_ids(site_data).union(site.tag_ids)
    site.save!

    site.audit!(user: @user, audit_batch: @audit_batch)
  end

  private

  def find_site(url)
    @team.sites.find_by(normalized_url: Link.url_without_scheme_and_www(url))
  end

  def site_tag_ids(site_data)
    tag_ids = @tag_ids + tag_ids_from_names(site_data["tag_names"] || [])
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
