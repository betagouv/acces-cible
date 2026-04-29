class RemoveNameFromTeams < ActiveRecord::Migration[8.1]
  def change
    remove_column :teams, :name, :string
  end
end
