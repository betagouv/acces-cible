module Checks
  class RunAxeOnHomepage < Check
    PRIORITY = 30
    AXE_SOURCE_PATH = Rails.root.join("vendor/javascript/axe.min.js").freeze
    AXE_LOCALE_PATH = Rails.root.join("vendor/javascript/axe.fr.json").freeze
    RGAA_AXE_RULES = [
      "aria-conditional-attr",
      "aria-deprecated-role",
      "aria-hidden-body",
      "aria-required-attr",
      "aria-required-parent",
      "aria-roles",
      "aria-valid-attr",
      "avoid-inline-spacing",
      "blink",
      "definition-list",
      "dlitem",
      "document-title",
      "html-has-lang",
      "html-lang-valid",
      "html-xml-lang-mismatch",
      "label-content-name-mismatch",
      "landmark-no-duplicate-banner",
      "landmark-no-duplicate-contentinfo",
      "landmark-one-main",
      "list",
      "listitem",
      "marquee",
      "meta-refresh",
      "meta-viewport",
      "scrollable-region-focusable",
      "table-fake-caption",
      "td-has-header",
      "valid-lang"
    ].to_json.freeze

    store_accessor :data, :passes, :incomplete, :inapplicable, :failures, :violations, :violation_data, :issues_total

    def tooltip?
      !completed?
    end

    def applicable_total
      completed? ? passes + incomplete + violations : nil
    end

    def checks_total
      completed? ? applicable_total + inapplicable : nil
    end

    def success_rate
      completed? ? (passes + incomplete) / applicable_total.to_f * 100 : nil
    end

    def human_success_rate
      to_percent(success_rate)
    end

    def violation_data
      (super || []).map { |data| AxeViolation.new(**data) }
    end

    def custom_badge_text
      human_success_rate
    end

    def custom_badge_status
      case success_rate
      when 100 then :success
      when 50..100 then :new
      when 1..50 then :warning
      else :error
      end
    end

    private

    def analyze!
      results = run_axe_check

      return if results.blank?

      {
        passes: results["passes"]&.count || 0,
        incomplete: results["incomplete"]&.count || 0,
        inapplicable: results["inapplicable"]&.count || 0,
        violations: results["violations"]&.count || 0,
        violation_data: format(results["violations"]),
        issues_total: results["violations"]&.sum { |v| v["nodes"]&.count || 0 } || 0,
      }
    end

    def run_axe_check
      locale = File.read(AXE_LOCALE_PATH)
      script_tag = File.read(AXE_SOURCE_PATH)
      script = "axe.configure({locale: #{locale} }); axe.run(document, \
                { runOnly: { type: 'rule', values: #{RGAA_AXE_RULES} }, reporter: 'v2'}).then(results => __f(results))"

      Browser.new.run_script_on_html(audit.home_page_html, script, script_tag)
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
