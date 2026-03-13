class AddUniqueConstraintToChecksAuditIdType < ActiveRecord::Migration[8.0]
  def change
    add_index :checks, [:audit_id, :type], unique: true
    # Since Postgresql can filter using the leftmost columns of a composite index,
    # we can now remove the basic audit_id index:
    remove_index :checks, :audit_id
  end
end
