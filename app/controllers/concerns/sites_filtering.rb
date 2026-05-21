module SitesFiltering
  extend ActiveSupport::Concern

  DEFAULT_DIRECTION = :desc
  SORT_DIRECTIONS = %i[asc desc].freeze

  private

  def filter_and_order_sites(scope, ids: [])
    scope = scope.where(id: ids) if ids.any?
    scope = filter_sites(scope)

    order_sites(scope)
  end

  def filter_sites(scope)
    scope = filter_sites_by_query(scope)
    scope = filter_sites_by_tag(scope)
    scope
  end

  def filter_sites_by_query(scope)
    return scope if search_query.blank?

    term = "%#{search_query}%"

    scope.where(
      "sites.name ILIKE ? OR sites.url ILIKE ?",
      term,
      term
    )
  end

  def filter_sites_by_tag(scope)
    return scope if selected_tag_id.blank?

    scope.joins(:site_tags).where(site_tags: { tag_id: selected_tag_id })
  end

  def order_sites(scope)
    sort_by_url? ? order_by_url(scope) : order_by_last_audited_at(scope)
  end

  def order_by_last_audited_at(scope)
    scope.order("sites.last_audited_at #{sort_direction.upcase} NULLS LAST, sites.created_at #{sort_direction.upcase}")
  end

  def order_by_url(scope)
    scope.order(normalized_url: sort_direction)
  end

  def sort_by_url?
    params.dig(:sort, :url).present?
  end

  def sort_direction
    direction = params.dig(:sort, :url).presence || params.dig(:sort, :last_audited_at).presence

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
