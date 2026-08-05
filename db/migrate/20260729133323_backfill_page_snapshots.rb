class BackfillPageSnapshots < ActiveRecord::Migration[8.1]
  disable_ddl_transaction

  def up
    %w[home accessibility].each do |kind|
      execute <<~SQL
        INSERT INTO page_snapshots (audit_id, kind, requested_url, current_url, html, status, content_type, created_at, updated_at)
        SELECT id, '#{kind}', #{kind}_page_url, #{kind}_page_url, #{kind}_page_html, 200, 'text/html', now(), now()
        FROM audits
        WHERE #{kind}_page_html IS NOT NULL

        ON CONFLICT (audit_id, kind) DO UPDATE SET
          requested_url = EXCLUDED.requested_url,
          current_url = EXCLUDED.current_url,
          html = EXCLUDED.html,
          status = EXCLUDED.status,
          content_type = EXCLUDED.content_type,
          updated_at = EXCLUDED.updated_at
      SQL
    end
  end
end
