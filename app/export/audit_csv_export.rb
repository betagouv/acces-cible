class AuditCsvExport
  COL_SEP = ";"
  UTF8_BOM = "\uFEFF"

  HEADERS = [
    I18n.t("audit.site_url_address"),
    I18n.t("audit.url"),
    I18n.t("audit.redirect_url"),
    I18n.t("tags.all"),
    I18n.t("check.completed_at"),
    I18n.t("checks.reachable.type"),
    I18n.t("checks.language_indication.type"),
    I18n.t("checks.accessibility_mention.type"),
    I18n.t("checks.find_accessibility_page.type"),
    I18n.t("checks.find_accessibility_page.hosted_on_audited_site"),
    I18n.t("checks.analyze_accessibility_page.auditor"),
    I18n.t("checks.analyze_accessibility_page.compliance_rate"),
    I18n.t("checks.analyze_accessibility_page.audit_date"),
    I18n.t("checks.analyze_accessibility_page.audit_update_date"),
    I18n.t("checks.analyze_accessibility_page.contact_email"),
    I18n.t("checks.analyze_accessibility_page.contact_form"),
    I18n.t("checks.analyze_schema.type"),
    I18n.t("checks.analyze_schema.years"),
    I18n.t("checks.analyze_plan.type"),
    I18n.t("checks.analyze_plan.years"),
    I18n.t("checks.accessibility_page_heading.type"),
    I18n.t("checks.run_axe_on_homepage.success_rate"),
  ].freeze

  def self.filename
    "sites_#{I18n.l(Time.zone.now, format: :file)}.csv"
  end

  def self.stream_csv_to(output_stream, audits)
    output_stream.write(UTF8_BOM)
    output_stream.write CSV.generate_line(HEADERS, col_sep: COL_SEP)

    audits.find_each(batch_size: 200) do |audit|
      output_stream.write CSV.generate_line(row_for(audit), col_sep: COL_SEP)
    end
  end

  def self.row_for(audit)
    site = audit.site
    reachable = audit.reachable
    language = audit.language_indication
    mention = audit.accessibility_mention
    find_accessibility = audit.find_accessibility_page
    analysis = audit.analyze_accessibility_page
    schema = audit.analyze_schema
    plan = audit.analyze_plan
    heading = audit.accessibility_page_heading
    axe = audit.run_axe_on_homepage

    [
      site.normalized_url,
      site.url,
      reachable.redirect_url,
      site.tags_list,
      audit.completed_at,
      reachable.completed?.to_s,
      extract_value(language, language.indication),
      extract_value(mention, mention.mention_text),
      extract_value(find_accessibility, find_accessibility.url),
      extract_value(find_accessibility, find_accessibility.internal.to_s),
      extract_value(analysis, analysis.auditor),
      extract_value(analysis, analysis.human_compliance_rate),
      extract_value(analysis, analysis.audit_date),
      extract_value(analysis, analysis.audit_update_date),
      extract_value(analysis, analysis.contact_email),
      extract_value(analysis, analysis.contact_form),
      extract_value(schema, link_or_found(schema, "analyze_schema.in_main_text")),
      extract_value(schema, schema.years&.join("-")),
      extract_value(plan, link_or_found(plan, "analyze_plan.in_main_text")),
      extract_value(plan, plan.years&.join("-")),
      extract_value(heading, heading.human_success_rate),
      extract_value(axe, axe.human_success_rate),
    ]
  end

  def self.extract_value(check, data)
    return I18n.t("check.status.failed") if check.nil?

    if check.aborted? || check.errored? || check.failed?
      check.human_status
    elsif data.blank?
      I18n.t("check.status.failed")
    else
      data
    end
  end

  def self.link_or_found(check, translation_key)
    return nil if check.nil?

    if check.text.present?
      I18n.t("checks.#{translation_key}")
    else
      check.link_url
    end
  end
end
