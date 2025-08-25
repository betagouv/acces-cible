class RemoveRetryCountFromChecks < ActiveRecord::Migration[8.0]
  def change
    remove_column :checks, :retry_count, :integer, null: false, default: 0
  end
end
