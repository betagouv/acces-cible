class RemoveRetryCountFromChecks < ActiveRecord::Migration[8.0]
  def change
    remove_column :checks, :retry_count, :integer, default: 0, null: false
  end
end
