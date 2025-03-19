module Checks
  class RunAxeOnHomepage < Check
    PRIORITY = 30

    store_accessor :data, :passes, :incomplete, :inapplicable, :failures, :violations, :issues_total

    def applicable_total = passed? ? passes + incomplete + violations : nil
    def checks_total = passed? ? applicable_total + inapplicable : nil
    def success_rate = passed? ? (passes + incomplete) / applicable_total.to_f * 100 : nil
    def human_success_rate = helpers.number_to_percentage(success_rate, precision: 2, strip_insignificant_zeros: true)

    def violation_data
      data["violation_data"]&.map { |data| AxeViolation.new(**data) } || []
    end

    private

    def custom_badge_text = human_success_rate
    def custom_badge_status
      case success_rate
      when 100 then :success
      when 50..100 then :new
      when 1..50 then :warning
      else :error
      end
    end

    def analyze!
      return unless (results = Browser.axe_check(audit.url))

      {
        passes: results["passes"]&.count || 0,
        incomplete: results["incomplete"]&.count || 0,
        inapplicable: results["inapplicable"]&.count || 0,
        violations: results["violations"]&.count || 0,
        violation_data: format(results["violations"]),
        issues_total: results["violations"]&.sum { |v| v["nodes"]&.count || 0 } || 0,
      }
    end

    def format(violations)
      return [] unless violations

      violations.map do |violation|
        {
          id: violation["id"],
          impact: violation["impact"],
          description: violation["description"],
          help: violation["help"],
          help_url: violation["helpUrl"],
          nodes: violation["nodes"].map do |node|
            {
              html: node["html"],
              impact: node["impact"],
              target: node["target"],
              failure_summary: node["failureSummary"]
            }
          end
        }
      end
    end
  end
end
