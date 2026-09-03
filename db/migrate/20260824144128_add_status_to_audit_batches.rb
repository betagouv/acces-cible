class AddStatusToAuditBatches < ActiveRecord::Migration[8.1]
  def change
    add_column :audit_batches, :status, :string, default: "draft", null: false
  end
end
