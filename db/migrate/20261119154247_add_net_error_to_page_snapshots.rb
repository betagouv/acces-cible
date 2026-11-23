class AddNetErrorToPageSnapshots < ActiveRecord::Migration[8.1]
  def change
    add_column :page_snapshots, :net_error, :string
  end
end
