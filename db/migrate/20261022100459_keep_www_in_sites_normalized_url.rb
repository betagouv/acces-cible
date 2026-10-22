class KeepWwwInSitesNormalizedUrl < ActiveRecord::Migration[8.1]
  def up
    Site.find_each do |site|
      site.update_columns(normalized_url: Link.url_without_scheme(site.url))
    end
  end

  def down
    Site.find_each do |site|
      site.update_columns(normalized_url: Link.url_without_scheme_and_www(site.url))
    end
  end
end
