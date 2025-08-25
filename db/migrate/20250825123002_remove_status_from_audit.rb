class RemoveStatusFromAudit < ActiveRecord::Migration[8.0]
  def change
    remove_column :audits, :status, :string, null: false, default: "pending"
  end
end
