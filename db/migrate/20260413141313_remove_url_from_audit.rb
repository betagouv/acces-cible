class RemoveUrlFromAudit < ActiveRecord::Migration[8.1]
  def change
    remove_column :audits, :url, :string
  end
end
