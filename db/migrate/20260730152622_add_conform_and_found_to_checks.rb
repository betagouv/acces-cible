class AddConformAndFoundToChecks < ActiveRecord::Migration[8.1]
  def change
    add_column :checks, :conform, :boolean
    add_column :checks, :found, :boolean
  end
end
