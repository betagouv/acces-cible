class RenameCheckedAtToCompletedAtInAudits < ActiveRecord::Migration[8.1]
  def change
    rename_column :audits, :checked_at, :completed_at
  end
end
