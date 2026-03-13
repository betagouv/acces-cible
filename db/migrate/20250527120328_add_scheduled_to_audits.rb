class AddScheduledToAudits < ActiveRecord::Migration[8.0]
  def change
    add_column :audits, :scheduled, :boolean, default: false
  end
end
