class AuditCsvExport
  COL_SEP = ";"
  UTF8_BOM = "\uFEFF"

  COLUMNS = (%w[site evaluated_url redirect_url] | AuditColumns::ALL | %w[declaration_url schema_url plan_url contact_email contact_form audit_url]).freeze
  HEADERS = COLUMNS.map { I18n.t("audits.index.columns.#{it}") }.freeze

  def self.filename
    "audits_#{I18n.l(Time.zone.now, format: :file)}.csv"
  end

  def self.stream_csv_to(output_stream, audits)
    output_stream.write(UTF8_BOM)
    output_stream.write CSV.generate_line(HEADERS, col_sep: COL_SEP)

    audits.find_each(batch_size: 200) do |audit|
      output_stream.write CSV.generate_line(row_for(audit), col_sep: COL_SEP)
    end
  end

  def self.row_for(audit)
    COLUMNS.map { value(audit, it) }
  end

  def self.value(audit, column)
    case column
    when "evaluated_url" then audit.site.url
    when "redirect_url" then audit.reachable.redirect_url
    when "declaration_url" then audit.find_accessibility_page.url
    when "schema_url" then audit.analyze_schema.link_url
    when "plan_url" then audit.analyze_plan.link_url
    when "contact_email" then audit.analyze_accessibility_page.contact_email
    when "contact_form" then audit.analyze_accessibility_page.contact_form
    when "audit_url" then Rails.application.routes.url_helpers.site_audit_url(audit.site, audit)
    else
      value = AuditColumns.value(audit, column)
      value.is_a?(Hash) ? value[:text] : value
    end
  end
end
