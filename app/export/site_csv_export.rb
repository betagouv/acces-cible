class SiteCsvExport
  COL_SEP = ";"

  HEADERS = [
    Audit.human(:site_url_address),
    Audit.human(:url),
    Audit.human(:redirected_url),
    Tag.human(:all),
    Check.human(:checked_at),
    Checks::Reachable.human(:type),
    Checks::LanguageIndication.human(:type),
    Checks::AccessibilityMention.human(:type),
    Checks::FindAccessibilityPage.human(:type),
    Checks::AnalyzeAccessibilityPage.human(:auditor),
    Checks::AnalyzeAccessibilityPage.human(:compliance_rate),
    Checks::AnalyzeAccessibilityPage.human(:audit_date),
    Checks::AnalyzeAccessibilityPage.human(:audit_update_date),
    Checks::AnalyzeSchema.human(:type),
    Checks::AnalyzeSchema.human(:years),
    Checks::AnalyzePlan.human(:type),
    Checks::AnalyzePlan.human(:years),
    Checks::AccessibilityPageHeading.human(:type),
    Checks::RunAxeOnHomepage.human(:success_rate),
  ].freeze

  def self.filename
    "sites_#{I18n.l(Time.zone.now, format: :file)}.csv"
  end

  def self.stream_csv_to(output_stream, sites)
    output_stream.write CSV.generate_line(HEADERS, col_sep: COL_SEP)

    sites.in_batches(of: 200) do |batch|
      batch.preloaded.each do |site|
        audit = site.audit

        reachable = audit&.reachable
        language = audit&.language_indication
        mention = audit&.accessibility_mention
        find_accessibility = audit&.find_accessibility_page
        analyze_accessibility = audit&.analyze_accessibility_page
        schema = audit&.analyze_schema
        plan = audit&.analyze_plan
        heading = audit&.accessibility_page_heading
        axe = audit&.run_axe_on_homepage

        row = [
          site.url_without_scheme_and_www,
          site.url,
          audit.reachable.redirect_url,
          site.tags_list,
          audit&.checked_at,
          reachable&.completed?.to_s,
          extract_value(language, language&.indication),
          extract_value(mention, mention&.mention_text),
          extract_value(find_accessibility, find_accessibility&.url),
          extract_value(analyze_accessibility, analyze_accessibility&.auditor),
          extract_value(analyze_accessibility, analyze_accessibility&.human_compliance_rate),
          extract_value(analyze_accessibility, analyze_accessibility&.audit_date),
          extract_value(analyze_accessibility, analyze_accessibility&.audit_update_date),
          extract_value(schema, link_or_found(schema, "analyze_schema.schema_in_main_text")),
          extract_value(schema, schema&.years&.join("-")),
          extract_value(plan, link_or_found(plan, "analyze_plan.plan_in_main_text")),
          extract_value(plan, plan&.years&.join("-")),
          extract_value(heading, heading&.human_success_rate),
          extract_value(axe, axe&.human_success_rate),
        ]

        output_stream.write CSV.generate_line(row, col_sep: COL_SEP)
      end
    end
  end

  def self.extract_value(check, data)
    return Check.human("status.failed") if check.nil?

    if check.aborted? || check.errored? || check.failed?
      check.human_status
    elsif data.blank?
      Check.human("status.failed")
    else
      data
    end
  end

  def self.link_or_found(check, translation_key)
    return nil if check.nil?

    if check.text.present?
      Check.human("checks.#{translation_key}")
    else
      check.link_url
    end
  end
end
