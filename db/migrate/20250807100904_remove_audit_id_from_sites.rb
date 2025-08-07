class RemoveAuditIdFromSites < ActiveRecord::Migration[8.0]
  def change
    remove_reference :sites, :audit, foreign_key: true
  end
end
