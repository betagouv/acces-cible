class AddAuditsCountToSite < ActiveRecord::Migration[8.0]
  def change
    add_column :sites, :audits_count, :integer, null: false, default: 0
    unless reverting?
      # Set counter for all objects in one query, without instantiating all models
      execute <<-SQL.squish
        UPDATE sites SET audits_count = (SELECT count(1) FROM audits WHERE audits.site_id = sites.id)
      SQL
    end
  end
end
