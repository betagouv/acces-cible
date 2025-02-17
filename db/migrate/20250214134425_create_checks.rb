class CreateChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :checks do |t|
      t.belongs_to :audit, null: false, foreign_key: true
      t.string :type, null: false
      t.string :status, null: false
      t.datetime :run_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :checked_at
      t.integer :attempts, null: false, default: 0
      t.jsonb :data, null: false, default: {}

      t.timestamps

      t.index [:status, :run_at], name: "index_checks_on_status_and_run_at"
      t.index :attempts, where: "status = 'failed' AND attempts > 0", name: "index_checks_on_retryable"
    end
  end
end
