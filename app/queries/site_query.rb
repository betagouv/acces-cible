class SiteQuery < SimpleDelegator
  def order_by(params)
    directions = [:asc, :desc]
    key, direction = params[:sort]&.to_unsafe_h&.first
    direction = direction.to_s.downcase.to_sym.presence_in(directions) || directions.first
    case key
    in :url
      sortable_url = Arel.sql("REGEXP_REPLACE(audits.url, '^https?://(www\.)?', '')")
      subquery = model.with_current_audit
        .select("sites.*, #{sortable_url} as sortable_url")
        .order(Arel.sql("sortable_url #{direction}"))
      from(subquery, :sites).order(Arel.sql("sortable_url #{direction}"))
    else # default sort
      subquery = model.with_current_audit
        .select("sites.*, audits.checked_at AS last_checked_at")
        .order(Arel.sql("last_checked_at #{direction} NULLS LAST"))
      from(subquery, :sites).order(Arel.sql("last_checked_at #{direction} NULLS LAST, sites.created_at #{direction}"))
    end
  end

  def filter_by(params)
    return self unless (filters = params[:search]).present?

    scope = self
    filters.compact_blank.each do |key, value|
      case key.to_sym
      when :q
        scope = scope.joins(:audits).where("sites.name ILIKE :term OR audits.url ILIKE :term", term: "%#{value}%")
      end
    end
    scope
  end
end
