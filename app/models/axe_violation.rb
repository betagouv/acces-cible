class AxeViolation < Data.define(:id, :impact, :description, :help, :help_url, :nodes)
  def description
    "#{super}."
  end

  def nodes_count
    nodes&.size || 0
  end

  def nodes_html
    nodes.collect { it["html"] }
  end

  def human_impact
    Checks::RunAxeOnHomepage.human("impacts.#{impact}")
  end

  def badge_level
    case impact
    when "minor" then :new
    when "moderate" then :info
    when "serious" then :warning
    when "critical" then :error
    end
  end
end
