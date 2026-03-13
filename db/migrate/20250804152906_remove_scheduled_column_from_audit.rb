class RemoveScheduledColumnFromAudit < ActiveRecord::Migration[8.0]
  def change
    remove_column :audits, :scheduled, :boolean, default: false, null: false
  end
end
