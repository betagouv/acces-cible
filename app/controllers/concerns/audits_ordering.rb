module AuditsOrdering
  extend ActiveSupport::Concern

  DEFAULT_COLUMN = "last_audit_at".freeze
  DEFAULT_DIRECTION = :desc
  FILLED_IN = ->(key) { "COALESCE(checks.data->>'#{key}', '') NOT IN ('', 'false')" }
  AXE_COUNT = ->(key) { "(checks.data->>'#{key}')::int" }
  CHECK_EXPRESSIONS = {
    reachable: { "reachable" => "checks.found" },
    find_accessibility_page: { "accessibility_page" => "checks.found" },
    accessibility_mention: { "declared_level" => "checks.data->>'mention'", "accessibility_mention" => "checks.found" },
    analyze_schema: { "schema" => "checks.found", "schema_quality" => "checks.conform" },
    analyze_plan: { "plan" => "checks.found", "plan_quality" => "checks.conform" },
    accessibility_page_heading: { "declaration_format" => "checks.conform" },
    analyze_accessibility_page: {
      "compliance_rate" => "(checks.data->>'compliance_rate')::numeric",
      "declaration_date" => FILLED_IN.("audit_date"),
      "standard" => FILLED_IN.("standard"),
      "auditor" => FILLED_IN.("auditor"),
      "law_article" => FILLED_IN.("mentions_article"),
      "contact_email" => FILLED_IN.("contact_email"),
      "contact_form" => FILLED_IN.("contact_form"),
    },
    run_axe_on_homepage: {
      "automated_tests_result" => AXE_COUNT.("passes"),
      "automated_tests_passed" => AXE_COUNT.("passes"),
      "automated_tests_applicable" => %w[passes incomplete violations].map(&AXE_COUNT).join(" + "),
      "automated_tests_inapplicable" => AXE_COUNT.("inapplicable"),
    },
  }.freeze

  private

  def order_audits(scope)
    column = AuditColumns::ALL.find { params.dig(:sort, it).present? } || DEFAULT_COLUMN

    direction = sort_direction(column)

    scope.order(Arel.sql("#{sort_expression(column)} #{direction} NULLS LAST, audits.id #{direction}"))
  end

  def sort_direction(column)
    params.dig(:sort, column) == "asc" ? "ASC" : DEFAULT_DIRECTION.to_s.upcase
  end

  def sort_expression(column)
    case column
    when "site" then "regexp_replace(sites.normalized_url, '^www[0-9]?\\.', '')"
    when "last_audit_at" then "audits.completed_at"
    when "legal_obligations" then "audits.legal_obligation_score"
    when "declaration_quality" then "audits.declaration_quality_score"
    when "evaluator" then "(SELECT users.name FROM users WHERE users.id = audits.user_id)"
    when "organization_label" then "(SELECT teams.organization_label FROM teams JOIN users ON users.siret = teams.siret WHERE users.id = audits.user_id)"
    when "tags" then "(SELECT string_agg(tags.name, ', ' ORDER BY tags.name) FROM tags JOIN site_tags ON site_tags.tag_id = tags.id WHERE site_tags.site_id = sites.id)"
    else
      check, expression = check_and_expression(column)
      "(SELECT #{expression} FROM checks WHERE checks.audit_id = audits.id AND checks.type = '#{Check.types.fetch(check).name}')"
    end
  end

  def check_and_expression(column)
    check, expressions = CHECK_EXPRESSIONS.find { |_, expressions| expressions.key?(column) }
    [check, expressions[column]] if check
  end
end
