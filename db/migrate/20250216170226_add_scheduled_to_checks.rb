class AddScheduledToChecks < ActiveRecord::Migration[8.0]
  def change
    add_column :checks, :scheduled, :boolean, null: false, default: false
  end
end
