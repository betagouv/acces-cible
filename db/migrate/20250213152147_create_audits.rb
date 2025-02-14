class CreateAudits < ActiveRecord::Migration[8.0]
  def change
    create_table :audits do |t|
      t.belongs_to :site, null: false, foreign_key: true
      t.string :url, null: false
      t.string :status, null: false
      t.integer :attempts, null: false, default: 0
      t.datetime :run_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps

      t.index :url
      t.index [:status, :run_at], name: "index_audits_on_status_and_run_at"
      t.index "REGEXP_REPLACE(url, '^https?://(www\.)?', '')", name: "index_audits_on_normalized_url"
      t.index :attempts, where: "status = 'failed' AND attempts > 0", name: "index_audits_on_retryable"
    end
  end
end
