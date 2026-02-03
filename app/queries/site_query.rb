class SiteQuery < SimpleDelegator
  def order_by(params)
    directions = [:asc, :desc]
    key, direction = params[:sort]&.to_unsafe_h&.first
    direction = direction.to_s.downcase.to_sym.presence_in(directions) || directions.first
    latest_audits = Audit
      .select("DISTINCT ON (audits.site_id) audits.*")
      .order(Arel.sql("audits.site_id, audits.created_at DESC"))
    case key
    in "url"
      sortable_url = Arel.sql("REGEXP_REPLACE(latest_audits.url, '^https?://(www\.)?', '')")
      subquery = model.joins("INNER JOIN (#{latest_audits.to_sql}) latest_audits ON latest_audits.site_id = sites.id")
                      .select("sites.*, #{sortable_url} as sortable_url")
                      .order(Arel.sql("sortable_url #{direction}"))
      from(subquery, :sites).order(Arel.sql("sortable_url #{direction}"))
    else
      subquery = model.joins("INNER JOIN (#{latest_audits.to_sql}) latest_audits ON latest_audits.site_id = sites.id")
                      .select("sites.*, latest_audits.completed_at AS last_completed_at")
                      .order(Arel.sql("last_completed_at #{direction} NULLS LAST"))
      from(subquery, :sites).order(Arel.sql("last_completed_at #{direction} NULLS LAST, sites.created_at #{direction}"))
    end
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
end
