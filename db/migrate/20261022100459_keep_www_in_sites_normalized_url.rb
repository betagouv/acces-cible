class KeepWwwInSitesNormalizedUrl < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE sites
      SET normalized_url = CONCAT('www.', normalized_url)
      WHERE (url LIKE 'https://www.%' OR url LIKE 'http://www.%')
        AND normalized_url NOT LIKE 'www.%'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE sites
      SET normalized_url = regexp_replace(normalized_url, '^www\\.', '')
      WHERE url LIKE 'https://www.%' OR url LIKE 'http://www.%'
    SQL
  end
end
