class RemoveNameOnSites < ActiveRecord::Migration[8.1]
  def change
    remove_column :sites, :name, :string
  end
end
