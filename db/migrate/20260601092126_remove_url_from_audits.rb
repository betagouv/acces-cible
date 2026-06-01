class RemoveUrlFromAudits < ActiveRecord::Migration[8.1]
  def change
    remove_column :audits, :url, :string

    change_column_null :sites, :url, false
    change_column_null :sites, :normalized_url, false
  end
end
