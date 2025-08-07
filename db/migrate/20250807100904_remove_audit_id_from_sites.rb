class RemoveAuditIdFromSites < ActiveRecord::Migration[8.0]
  def up
    return unless column_exists?(:sites, :audit)

    remove_reference :sites, :audit, foreign_key: foreign_key_exists?(:sites, :audit)
  end
end
