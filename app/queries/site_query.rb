class SiteQuery < SimpleDelegator
  DIRECTIONS = {
    "asc" => :asc,
    "desc" => :desc,
  }.freeze

  def order_by_url(direction)
    direction = normalize_direction(direction)
    sortable_url = Arel.sql("REGEXP_REPLACE(audits.url, '^https?://(www\\.)?', '')")
    subquery = model.with_current_audit
                    .select("sites.*, #{sortable_url} AS sortable_url")
                    .order(Arel.sql(direction == :desc ? "sortable_url DESC" : "sortable_url ASC"))
    from(subquery, :sites).order(Arel.sql(direction == :desc ? "sortable_url DESC" : "sortable_url ASC"))
  end

  def order_by_completed_at(direction)
    direction = normalize_direction(direction)
    subquery = model.with_current_audit
                    .select("sites.*, audits.completed_at AS last_completed_at")
                    .order(Arel.sql(direction == :desc ? "last_completed_at DESC NULLS LAST" : "last_completed_at ASC NULLS LAST"))
    from(subquery, :sites).order(
      Arel.sql(direction == :desc ? "last_completed_at DESC NULLS LAST, sites.created_at DESC" : "last_completed_at ASC NULLS LAST, sites.created_at ASC")
    )
  end

  def filter_by(params)
    return self unless (filters = params[:filter]).present?

    scope = self
    filters.compact_blank.each do |key, value|
      case key.to_sym
      when :q
        scope = scope.joins(:audits).where("sites.name ILIKE :term OR audits.url ILIKE :term", term: "%#{value}%")
      when :tag_id
        scope = scope.joins(:site_tags)
                     .where(site_tags: { tag_id: value })
      end
    end
    scope
  end

  private

  def normalize_direction(direction)
    DIRECTIONS.fetch(direction.to_s.downcase, :asc)
  end
end
