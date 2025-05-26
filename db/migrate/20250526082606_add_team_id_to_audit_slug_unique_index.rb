class AddTeamIdToAuditSlugUniqueIndex < ActiveRecord::Migration[8.0]
  def change
    remove_index :sites, :slug, unique: true
    add_index :sites, [:slug, :team_id], unique: true
  end
end
