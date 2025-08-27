class RenameAuditCheckedAtToCompletedAt < ActiveRecord::Migration[8.0]
  def change
    rename_column :audits, :checked_at, :completed_at
  end
end
