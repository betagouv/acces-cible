class AddAuditBatchToAudits < ActiveRecord::Migration[8.1]
  def change
    add_reference :audits, :audit_batch, null: true, foreign_key: true
  end
end
