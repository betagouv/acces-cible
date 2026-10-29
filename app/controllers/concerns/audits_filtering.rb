module AuditsFiltering
  extend ActiveSupport::Concern
  include AuditsOrdering

  REDIRECTED = "COALESCE(checks.data->>'redirect_url', '') <> ''".freeze
  REACHABLE_CONDITIONS = {
    "reachable" => "(checks.found AND NOT #{REDIRECTED})",
    "redirected" => "(checks.found AND #{REDIRECTED})",
    "unreachable" => "NOT checks.found"
  }.freeze
  DECLARED_LEVELS = %w[non partiellement totalement].freeze

  private

  def scoped_audits(ids: [])
    scope = current_audits.joins(:site)
    scope = scope.latest_per_site if latest_history?
    scope = scope.where(site_id: ids) if ids.any?
    scope = filter_audits(scope)

    order_audits(scope)
  end

  def current_audits
    team_scope? ? Audit.for_team(current_user.team) : Audit.for_user(current_user)
  end

  def latest_history?
    params.dig(:filter, :history) == "latest"
  end

  def team_scope?
    params.dig(:filter, :scope) == "team"
  end

  def filter_audits(scope)
    scope = filter_by_query(scope)
    scope = filter_by_tag(scope)
    scope = filter_by_reachable(scope)
    scope = filter_by_declared_level(scope)
    filter_by_checks(scope)
  end

  def filter_by_query(scope)
    return scope if search_query.blank?

    term = "%#{search_query}%"
    scope.where("sites.normalized_url ILIKE :term OR sites.url ILIKE :term", term:)
  end

  def filter_by_tag(scope)
    return scope if selected_tag_id.blank?

    scope.joins(site: :site_tags).where(site_tags: { tag_id: selected_tag_id })
  end

  def filter_by_reachable(scope)
    condition = REACHABLE_CONDITIONS[params.dig(:filter, :reachable)]
    return scope unless condition

    scope.where(id: audit_ids_with_check(:reachable, condition))
  end

  def filter_by_declared_level(scope)
    level = params.dig(:filter, :declared_level)
    return scope unless level.in?(DECLARED_LEVELS)

    scope.where(id: audit_ids_with_check(:accessibility_mention, ["checks.data->>'mention' = ?", level]))
  end

  def filter_by_checks(scope)
    AuditColumns::BOOLEAN_FILTERS.reduce(scope) { |filtered, column| filter_by_check(filtered, column) }
  end

  def filter_by_check(scope, column)
    check, condition = check_and_expression(column)

    case params.dig(:filter, column)
    when "true" then scope.where(id: audit_ids_with_check(check, condition))
    when "false" then scope.where.not(id: audit_ids_with_check(check, condition))
    else scope
    end
  end

  def audit_ids_with_check(check, condition)
    Check.types.fetch(check).where(condition).select(:audit_id)
  end

  def selected_tag_id
    params.dig(:filter, :tag_id).presence
  end

  def search_query
    params.dig(:filter, :q).to_s.strip.presence
  end
end
