class RemoveScheduledFromChecks < ActiveRecord::Migration[8.0]
  def change
    remove_column :checks, :scheduled, :boolean, null: false, default: false
  end
end
