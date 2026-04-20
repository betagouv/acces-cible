class AddUrlToSite < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :url, :string
    add_column :sites, :normalized_url, :string
  end
end
