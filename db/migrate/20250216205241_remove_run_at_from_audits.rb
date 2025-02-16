class RemoveRunAtFromAudits < ActiveRecord::Migration[8.0]
  def change
    remove_column :audits, :run_at, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }
  end
end
