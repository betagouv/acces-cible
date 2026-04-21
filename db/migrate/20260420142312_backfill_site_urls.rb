class BackfillSiteUrls < ActiveRecord::Migration[8.1]
  def up
    Site.includes(:audits).find_in_batches do |sites|
      sites.each do |site|
        audit_url = site.audits.last&.url
        next if audit_url.blank?
        normalized_url = normalize_url_without_scheme_and_www(audit_url)

        # update_columns here is needed because of an overriding url setter method in Site model
        site.update_columns(url: audit_url, normalized_url:, updated_at: Time.zone.now)
      end
    end
  end

  def down
    Audit.includes(:site).find_in_batches do |audits|
      audits.each do |audit|
        site_url = audit.site&.url
        next if site_url.blank? || audit.url.present?

        audit.update(url: site_url)
      end
    end
  end

  private

  # Need to reproduce Link.url_without_scheme_and_www
  # to stay true to existing data
  def normalize_url_without_scheme_and_www(url)
    parsed_url = URI.parse(url)
    hostname = parsed_url.host.gsub(/\Awww\./, "")
    path = parsed_url.path == "/" ? nil : parsed_url.path
    [hostname, path].compact.join(nil)
  end
end
