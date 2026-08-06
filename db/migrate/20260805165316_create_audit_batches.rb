class CreateAuditBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_batches do |t|
      t.bigint :user_id, null: false
      t.string :kind, null: false
      t.timestamps
      t.index [:user_id]
    end

    add_foreign_key :audit_batches, :users
  end
end
