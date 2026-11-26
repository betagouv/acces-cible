class AddErrorToPageSnapshots < ActiveRecord::Migration[8.1]
  def change
    add_column :page_snapshots, :error, :string
  end
end
