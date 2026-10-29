module AuditsOrdering
  extend ActiveSupport::Concern

  DEFAULT_COLUMN = "last_audit_at".freeze
  DEFAULT_DIRECTION = "desc".freeze

  included do
    helper_method :sortable_column?
  end

  private

  def column_value(column)
    case column
    when "accessibility_mention" then accessibility_mention_value
    when "accessibility_page" then accessibility_page_value
    when "automated_tests_applicable" then automated_tests_applicable_value
    when "automated_tests_inapplicable" then automated_tests_inapplicable_value
    when "automated_tests_result", "automated_tests_passed" then automated_tests_passed_value
    when "compliance_rate" then compliance_rate_value
    when "declaration_date" then declaration_text_value("audit_date")
    when "auditor", "standard", "contact_email", "contact_form" then declaration_text_value(column)
    when "declaration_quality" then "audits.declaration_quality_score"
    when "declared_level" then declared_level_value
    when "evaluator" then "users.name"
    when "last_audit_at" then "audits.completed_at"
    when "law_article" then law_article_value
    when "legal_obligations" then "audits.legal_obligation_score"
    when "organization_label" then "teams.organization_label"
    when "plan" then check_value(Checks::AnalyzePlan, :found)
    when "reachable" then reachable_value
    when "schema" then check_value(Checks::AnalyzeSchema, :found)
    when "site" then site_value
    end
  end

  def sortable_column?(column)
    column_value(column).present?
  end

  def order_audits(scope)
    column = params.fetch(:sort, {}).keys.first
    column = DEFAULT_COLUMN unless sortable_column?(column)
    direction = params.dig(:sort, column).presence_in(%w[asc desc]) || DEFAULT_DIRECTION
    nulls_direction = direction == "asc" ? "FIRST" : "LAST"

    scope.left_joins(user: :team).order(Arel.sql("#{column_value(column)} #{direction} NULLS #{nulls_direction}"), id: direction)
  end

  def site_value
    "regexp_replace(sites.normalized_url, '^www[0-9]?\\.', '')"
  end

  def reachable_value
    check_value(Checks::Reachable.done, "CASE WHEN NOT checks.found THEN 'unreachable' WHEN checks.data->>'redirect_url' IS NOT NULL THEN 'redirected' ELSE 'reachable' END")
  end

  def accessibility_page_value
    check_value(Checks::FindAccessibilityPage.done, :found)
  end

  def accessibility_mention_value
    check_value(Checks::AccessibilityMention.in_state(:completed), :found)
  end

  def declared_level_value
    check_value(Checks::AccessibilityMention.where(found: true), "checks.data->>'mention'")
  end

  def compliance_rate_value
    check_value(Checks::AnalyzeAccessibilityPage, "(checks.data->>'compliance_rate')::numeric")
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

  def check_value(checks, column)
    "(#{checks.where('checks.audit_id = audits.id').select(column).to_sql})"
  end
end
