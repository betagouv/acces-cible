class AddTeamIdToSites < ActiveRecord::Migration[8.0]
  def change
    add_reference :sites, :team, foreign_key: true
    up_only do
      team_id = Team.find_or_create_by(name: "Équipe par défaut", siret: "00000000000000").id
      Site.update_all(team_id:)
    end
    change_column_null :sites, :team_id, false
  end
end
