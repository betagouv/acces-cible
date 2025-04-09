class SiteQuery < SimpleDelegator
  def order_by(key, direction:)
    directions = [:asc, :desc]
    direction = direction.to_s.downcase.to_sym.presence_in(directions) || directions.first
    case key
    in :url
      sortable_url = Arel.sql("REGEXP_REPLACE(audits.url, '^https?://(www\.)?', '')")
      subquery = model.joins(:audits)
        .select("DISTINCT ON (sites.id) sites.*, #{sortable_url} as sortable_url")
        .order("sites.id, sortable_url #{direction}")
      from(subquery, :sites).order(Arel.sql("sortable_url #{direction}"))
    else # default sort
      joins("LEFT JOIN (
          SELECT site_id, MAX(checked_at) as latest_check
          FROM audits
          GROUP BY site_id
        ) latest_audits ON sites.id = latest_audits.site_id")
      .order("latest_audits.latest_check #{direction} NULLS LAST, sites.created_at #{direction}")
    end
  end
end
