module AuditsFiltering
  extend ActiveSupport::Concern

  DEFAULT_DIRECTION = :desc
  SORT_DIRECTIONS = %i[asc desc].freeze

  private

  def scoped_audits(ids: [])
    scope = current_audits.last_per_site.joins(:site)
    scope = scope.where(site_id: ids) if ids.any?
    scope = filter_audits(scope)

    order_audits(scope)
  end

  def current_audits
    team_scope? ? Audit.for_team(current_user.team) : Audit.for_user(current_user)
  end

  def team_scope?
    params.dig(:filter, :scope) == "team"
  end

  def filter_audits(scope)
    scope = filter_by_query(scope)
    filter_by_tag(scope)
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

  def order_audits(scope)
    if params.dig(:sort, :url).present?
      scope.order("sites.normalized_url #{sort_direction.upcase}")
    else
      scope.order(created_at: sort_direction)
    end
  end

  def sort_direction
    direction = (params.dig(:sort, :url) || params.dig(:sort, :last_audited_at)).to_s.presence

    return DEFAULT_DIRECTION if direction.blank?

    direction = direction.to_sym
    direction.in?(SORT_DIRECTIONS) ? direction : DEFAULT_DIRECTION
  end

  def selected_tag_id
    params.dig(:filter, :tag_id).presence
  end

  def search_query
    params.dig(:filter, :q).to_s.strip.presence
  end
end
