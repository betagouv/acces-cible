class CreateMetabaseAuditAndSiteView < ActiveRecord::Migration[8.1]
  REDACTED_TEAM_SIRET = "6024"

  def up
    execute "CREATE SCHEMA metabase"

    execute <<~SQL
      CREATE VIEW metabase.sites WITH (security_barrier = true) AS
      SELECT
        sites.id,
        sites.audits_count,
        sites.created_at,
        sites.last_audited_at,
        CASE WHEN teams.siret = '#{REDACTED_TEAM_SIRET}' THEN NULL ELSE sites.name END AS name,
        CASE WHEN teams.siret = '#{REDACTED_TEAM_SIRET}' THEN NULL ELSE sites.normalized_url END AS normalized_url,
        CASE WHEN teams.siret = '#{REDACTED_TEAM_SIRET}' THEN NULL ELSE sites.slug END AS slug,
        sites.tags_count,
        sites.team_id,
        sites.updated_at,
        CASE WHEN teams.siret = '#{REDACTED_TEAM_SIRET}' THEN NULL ELSE sites.url END AS url
      FROM sites
      INNER JOIN teams ON teams.id = sites.team_id
    SQL

    execute <<~SQL
      CREATE VIEW metabase.audits WITH (security_barrier = true) AS
      SELECT
        audits.id,
        CASE WHEN teams.siret = '#{REDACTED_TEAM_SIRET}' THEN NULL ELSE audits.accessibility_page_html END AS accessibility_page_html,
        CASE WHEN teams.siret = '#{REDACTED_TEAM_SIRET}' THEN NULL ELSE audits.accessibility_page_url END AS accessibility_page_url,
        audits.completed_at,
        audits.created_at,
        CASE WHEN teams.siret = '#{REDACTED_TEAM_SIRET}' THEN NULL ELSE audits.home_page_html END AS home_page_html,
        CASE WHEN teams.siret = '#{REDACTED_TEAM_SIRET}' THEN NULL ELSE audits.home_page_url END AS home_page_url,
        audits.site_id,
        audits.updated_at,
        audits.user_id
      FROM audits
      INNER JOIN sites ON sites.id = audits.site_id
      INNER JOIN teams ON teams.id = sites.team_id
    SQL
  end

  def down
    execute "DROP VIEW IF EXISTS metabase.audits"
    execute "DROP VIEW IF EXISTS metabase.sites"
    execute "DROP SCHEMA metabase"
  end
end
