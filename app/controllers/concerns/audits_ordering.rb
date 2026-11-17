module AuditsOrdering
  extend ActiveSupport::Concern

  DEFAULT_COLUMN = "last_audit_at".freeze
  DEFAULT_DIRECTION = "desc".freeze
  FINISHED_STATES = %i[completed failed errored].freeze

  included do
    helper_method :sortable_column?
  end

  private

  def column_value(column)
    case column
    when "site" then site_value
    when "last_audit_at" then last_audit_at_value
    when "legal_obligations" then legal_obligations_value
    when "declaration_quality" then declaration_quality_value
    when "evaluator" then evaluator_value
    when "organization_label" then organization_label_value
    when "tags" then tags_value
    when "reachable" then reachable_value
    when "accessibility_page" then accessibility_page_value
    when "accessibility_mention" then accessibility_mention_value
    when "declared_level" then declared_level_value
    when "schema" then schema_value
    when "plan" then plan_value
    when "compliance_rate" then compliance_rate_value
    when "declaration_date" then declaration_date_value
    when "standard" then standard_value
    when "auditor" then auditor_value
    when "law_article" then law_article_value
    when "contact_email" then contact_email_value
    when "contact_form" then contact_form_value
    when "automated_tests_result", "automated_tests_passed" then automated_tests_passed_value
    when "automated_tests_applicable" then automated_tests_applicable_value
    when "automated_tests_inapplicable" then automated_tests_inapplicable_value
    end
  end

  def sortable_column?(column)
    column_value(column).present?
  end

  def order_audits(scope)
    column = params.fetch(:sort, {}).keys.find { |name| sortable_column?(name) } || DEFAULT_COLUMN
    direction = params.dig(:sort, column).presence_in(%w[asc desc]) || DEFAULT_DIRECTION
    nulls_direction = direction == "asc" ? "FIRST" : "LAST"

    scope.order(Arel.sql("#{column_value(column)} #{direction} NULLS #{nulls_direction}"), id: direction)
  end

  def site_value
    "regexp_replace(sites.normalized_url, '^www[0-9]?\\.', '')"
  end

  def last_audit_at_value
    "audits.completed_at"
  end

  def legal_obligations_value
    score_value("legal_obligation_score")
  end

  def declaration_quality_value
    score_value("declaration_quality_score")
  end

  def evaluator_value
    "(SELECT users.name FROM users WHERE users.id = audits.user_id)"
  end

  def organization_label_value
    "(SELECT teams.organization_label FROM teams JOIN users ON users.siret = teams.siret WHERE users.id = audits.user_id)"
  end

  def tags_value
    "(SELECT string_agg(tags.name, ', ' ORDER BY tags.name) FROM tags JOIN site_tags ON site_tags.tag_id = tags.id WHERE site_tags.site_id = sites.id)"
  end

  def reachable_value
    check_value(Checks::Reachable.in_state(*FINISHED_STATES), "CASE WHEN NOT checks.found THEN 'unreachable' WHEN checks.data->>'redirect_url' IS NOT NULL THEN 'redirected' ELSE 'reachable' END")
  end

  def accessibility_page_value
    check_value(Checks::FindAccessibilityPage.in_state(*FINISHED_STATES), :found)
  end

  def accessibility_mention_value
    check_value(Checks::AccessibilityMention.in_state(:completed), :found)
  end

  def declared_level_value
    check_value(Checks::AccessibilityMention.where(found: true), "checks.data->>'mention'")
  end

  def schema_value
    check_value(Checks::AnalyzeSchema.where(audit_id: audit_ids_with_declaration), :found)
  end

  def plan_value
    check_value(Checks::AnalyzePlan.where(audit_id: audit_ids_with_declaration), :found)
  end

  def compliance_rate_value
    check_value(Checks::AnalyzeAccessibilityPage, "(checks.data->>'compliance_rate')::numeric")
  end

  def declaration_date_value
    declaration_text_value("audit_date")
  end

  def standard_value
    declaration_text_value("standard")
  end

  def auditor_value
    declaration_text_value("auditor")
  end

  def contact_email_value
    declaration_text_value("contact_email")
  end

  def contact_form_value
    declaration_text_value("contact_form")
  end

  def law_article_value
    check_value(Checks::AnalyzeAccessibilityPage.in_state(:completed), "COALESCE(checks.data->>'mentions_article', '') NOT IN ('', 'false')")
  end

  def automated_tests_passed_value
    check_value(Checks::RunAxeOnHomepage, "(checks.data->>'passes')::int")
  end

  def automated_tests_applicable_value
    check_value(Checks::RunAxeOnHomepage, "(checks.data->>'passes')::int + (checks.data->>'incomplete')::int + (checks.data->>'violations')::int")
  end

  def automated_tests_inapplicable_value
    check_value(Checks::RunAxeOnHomepage, "(checks.data->>'inapplicable')::int")
  end

  def declaration_text_value(key)
    check_value(Checks::AnalyzeAccessibilityPage, "NULLIF(checks.data->>'#{key}', '')")
  end

  def score_value(score)
    "CASE WHEN audits.id IN (#{audit_ids_with_declaration.to_sql}) THEN audits.#{score} END"
  end

  def check_value(checks, column)
    "(#{checks.where('checks.audit_id = audits.id').select(column).to_sql})"
  end

  def audit_ids_with_declaration
    Checks::FindAccessibilityPage.where(found: true).select(:audit_id)
  end
end
