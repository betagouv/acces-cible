module Checks
  class RunAxeOnHomepage < Check
    PRIORITY = 30

    store_accessor :data, :passes, :incomplete, :inapplicable, :violations, :total_issues

    def failures = violations&.size
    def failure_rate = total_issues ? failures / (total_issues || 0) : nil

    private

    def analyze!
      { output: run_axe_checks }
    end

    def run_axe_checks
      return unless (results = Browser.axe_check(audit.url))

      {
        passes: results["passes"]&.count || 0,
        incomplete: results["incomplete"]&.count || 0,
        inapplicable: results["inapplicable"]&.count || 0,
        violations: format(results["violations"]),
        total_issues: results["violations"]&.sum { |v| v["nodes"]&.count || 0 } || 0,
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
