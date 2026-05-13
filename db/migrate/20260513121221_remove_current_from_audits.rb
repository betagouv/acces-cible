class RemoveCurrentFromAudits < ActiveRecord::Migration[8.1]
  def change
    remove_column :audits, :current, :boolean
  end
end
