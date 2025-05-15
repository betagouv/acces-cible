class AddRetryAttributesToChecks < ActiveRecord::Migration[8.0]
  def change
    change_table :checks, bulk: true do |t|
      t.datetime :retry_at
      t.integer :retry_count, default: 0, null: false
    end
  end
end
