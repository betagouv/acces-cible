class RemoveAttemptsFromChecks < ActiveRecord::Migration[8.0]
  def change
    remove_index :checks, :attempts, where: "status = 'failed' AND attempts > 0", name: "index_checks_on_retryable" if reverting?
    remove_column :checks, :attempts, :integer, default: 0, null: false
  end
end
