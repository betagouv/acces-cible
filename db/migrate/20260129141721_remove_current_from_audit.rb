class RemoveCurrentFromAudit < ActiveRecord::Migration[8.1]
  def change
    remove_index :audits, name: "index_audits_on_site_id_and_current"
    remove_column :audits, :current, :boolean, default: false, null: false
  end
end
