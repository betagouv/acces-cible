class CreatePageSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :page_snapshots do |t|
      t.bigint :audit_id, null: false
      t.string :kind, null: false
      t.string :requested_url
      t.string :current_url
      t.text :html
      t.integer :status
      t.string :content_type
      t.timestamps
      t.index [:audit_id, :kind], unique: true
    end

    add_foreign_key :page_snapshots, :audits
  end
end
