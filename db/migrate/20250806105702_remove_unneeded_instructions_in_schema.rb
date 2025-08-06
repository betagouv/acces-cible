class RemoveUnneededInstructionsInSchema < ActiveRecord::Migration[8.0]
  def change
    drop_schema "acces_cible_development_cable"
    drop_schema "acces_cible_development_cache"
    drop_schema "acces_cible_development_queue"

    remove_index :sites, :audit_id, if_exists: true
  end
end
