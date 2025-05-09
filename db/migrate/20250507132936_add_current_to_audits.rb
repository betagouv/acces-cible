class AddCurrentToAudits < ActiveRecord::Migration[8.0]
  def change
    change_table :audits do |t|
      t.boolean :current, null: false, default: false
      t.index [:site_id, :current], unique: true, where: "current = true"
    end

    up_only do
      say_with_time "set current = true for latest checked audits" do
        execute <<~SQL.squish
          WITH latest_audits AS (
            SELECT id
            FROM (
              SELECT id, site_id,
                     ROW_NUMBER() OVER (PARTITION BY site_id ORDER BY created_at DESC) as rn
              FROM audits
              WHERE status != 'pending'
            ) ranked_audits
            WHERE rn = 1
          )
          UPDATE audits
          SET current = true
          WHERE id IN (SELECT id FROM latest_audits)
        SQL
      end
    end
  end
end
