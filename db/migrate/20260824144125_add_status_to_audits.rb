class AddStatusToAudits < ActiveRecord::Migration[8.1]
  def change
    add_column :audits, :status, :string, default: "launched", null: false
    change_column_default :audits, :status, from: "launched", to: "draft"

    add_index :audits, [:site_id, :status]
    remove_index :audits, column: :site_id
  end
end
