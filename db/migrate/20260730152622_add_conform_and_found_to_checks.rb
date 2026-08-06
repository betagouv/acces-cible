class AddConformAndFoundToChecks < ActiveRecord::Migration[8.1]
  def change
    add_column :checks, :conform, :boolean, default: false
    add_column :checks, :found, :boolean, default: false
  end
end
