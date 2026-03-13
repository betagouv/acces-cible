class RemoveAttemptsFromAudits < ActiveRecord::Migration[8.0]
  def change
    remove_index :audits, :attempts, where: "status = 'failed' AND attempts > 0", name: "index_audits_on_retryable" if reverting?
    remove_column :audits, :attempts, :integer, default: 0, null: false
  end
end
