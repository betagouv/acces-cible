module SitesFiltering
  extend ActiveSupport::Concern

  DEFAULT_DIRECTION = "desc"
  SORT_DIRECTIONS = %w[asc desc].freeze

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
      "sites.name ILIKE ? OR audits.url ILIKE ?",
      term,
      term
    )
  end

  def filter_sites_by_tag(scope)
    return scope if selected_tag_id.blank?

    scope.joins(:site_tags).where(site_tags: { tag_id: selected_tag_id })
  end

  def order_sites(scope)
    return order_by_url(scope) if sort_by_url?

    order_by_completed_at(scope)
  end

  def order_by_completed_at(scope)
    direction = sort_direction.upcase
    scope.order("audits.completed_at #{direction} NULLS LAST, sites.created_at #{direction}")
  end

  def order_by_url(scope)
    scope.order(
      Arel.sql(
        "REGEXP_REPLACE(audits.url, '^https?://(www\\.)?', '') #{sort_direction.upcase}"
      )
    )
  end

  def sort_by_url?
    params.dig(:sort, :url).present?
  end

  def sort_direction
    direction = params.dig(:sort, :url).presence || params.dig(:sort, :completed_at).presence

    direction.in?(SORT_DIRECTIONS) ? direction : DEFAULT_DIRECTION
  end

  def selected_tag_id
    params.dig(:filter, :tag_id).presence
  end

  def search_query
    params.dig(:filter, :q).to_s.strip.presence
  end
end
