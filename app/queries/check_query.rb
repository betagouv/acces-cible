class CheckQuery < SimpleDelegator
  def filter_by(params)
    return self unless (filters = params[:filter]).present?

    scope = self
    filters = JSON.parse(filters.gsub(" => ", ": ")) if filters.is_a?(String)
    filters.compact_blank.each do |key, value|
      case key.to_sym
      when :q
        scope = scope.joins(:check_transitions).where("check_transitions.metadata::text ILIKE :term", term: "%#{value}%")
      when :status
        scope = scope.joins(:check_transitions).where(check_transitions: { to_state: value, most_recent: true })
      when :type
        scope = scope.where(type: "Checks::#{value.classify}")
      when :site_id
        scope = scope.where(audit: { site_id: value })
      end
    end
    scope
  end
end
