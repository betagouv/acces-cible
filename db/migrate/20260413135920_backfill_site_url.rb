class BackfillSiteUrl < ActiveRecord::Migration[8.1]
  def up
    ## BATCH BITCH
    Site.all.each do |site|
      audit_url = site.audits.last.url
      site.update(url: audit_url)
      site.update(normalized_url: audit_url.gsub(/^https?:\/\/(www\.)?/, ''))
    end
  end

  def down
    ## BATCH BITCH

    Audit.all.each do |audit|
      audit.update(url: audit.site.url)
    end
  end
end
