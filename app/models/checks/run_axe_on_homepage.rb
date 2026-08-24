module Checks
  class RunAxeOnHomepage < Check
    PRIORITY = 30
    AXE_SOURCE_PATH = Rails.root.join("vendor/javascript/axe.min.js").freeze
    AXE_LOCALE_PATH = Rails.root.join("vendor/javascript/axe.fr.json").freeze
    AXE_RULE_TO_RGAA_CRITERION = {
      "aria-conditional-attr" => "7.1",
      "aria-deprecated-role" => "7.1",
      "aria-hidden-body" => "7.1",
      "aria-required-attr" => "7.1",
      "aria-required-parent" => "7.1",
      "aria-roles" => "7.1",
      "aria-valid-attr" => "7.1",
      "blink" => "13.8",
      "definition-list" => "9.3",
      "dlitem" => "9.3",
      "document-title" => "8.5",
      "html-has-lang" => "8.3",
      "html-lang-valid" => "8.4",
      "html-xml-lang-mismatch" => "8.4",
      "list" => "9.3",
      "listitem" => "9.3",
      "marquee" => "13.8",
      "meta-refresh" => "13.1",
      "meta-viewport" => "13.9",
      "scrollable-region-focusable" => "7.3",
      "valid-lang" => "8.7",
      "landmark-no-duplicate-banner" => "9.2",
      "landmark-no-duplicate-contentinfo" => "9.2",
      "landmark-one-main" => "9.2",
      "label-content-name-mismatch" => "11.2",
      "table-fake-caption" => "5.6",
      "td-has-header" => "5.7",
      "avoid-inline-spacing" => "10.4",
    }.freeze
    RGAA_AXE_RULES = AXE_RULE_TO_RGAA_CRITERION.keys.to_json.freeze
    RGAA_CRITERION_DOCUMENTATION_BASE_URL = "https://accessibilite.numerique.gouv.fr/methode/criteres-et-tests".freeze
    LEGACY_STATUSES = { "violation" => "violations", "passed" => "passes", "unknown" => "incomplete" }.freeze

    store_accessor :data, :passes, :incomplete, :inapplicable, :violations, :issues_total, :axe_rule_results

    def tooltip?
      !completed?
    end

    def applicable_total
      completed? ? passes + incomplete + violations : nil
    end

    def success_rate
      completed? ? (passes + incomplete) / applicable_total.to_f * 100 : nil
    end

    def human_success_rate
      to_percent(success_rate)
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

    def axe_rule_results
      (super.presence || data["violation_data"] || []).map do |rule|
        status = LEGACY_STATUSES[rule["status"]] || rule["status"] || "violations"
        AxeViolation.new(
          id: rule["id"],
          status: status&.to_sym,
          impact: rule["impact"],
          description: rule["description"],
          help: rule["help"],
          help_url: rule["help_url"],
          nodes: rule["nodes"]
        )
      end
    end

    def violation_data
      axe_rule_results.select { it.status == :violations }
    end

    def automated_test_results
      return [] unless completed?

      rules_by_id = axe_rule_results.index_by(&:id)

      AXE_RULE_TO_RGAA_CRITERION.map.with_index(1) do |(rule_id, criterion), position|
        rule = rules_by_id[rule_id]
        status = rule&.status || :incomplete

        {
          position:,
          rule_id:,
          title: t("checks.run_axe_on_homepage.rules.#{rule_id}"),
          help_url: rule&.help_url,
          criterion:,
          status:,
          violation: status == :violations ? rule : nil
        }
      end
    end

    def rgaa_criterion_documentation_url(criterion)
      "#{RGAA_CRITERION_DOCUMENTATION_BASE_URL}##{criterion}"
    end

    private

    def analyze!
      results = run_axe_check

      return if results.blank?

      rule_results = format_axe_rule_results(results)
      tally = rule_results.pluck(:status).tally

      {
        passes: tally[:passes] || 0,
        incomplete: tally[:incomplete] || 0,
        inapplicable: tally[:inapplicable] || 0,
        violations: tally[:violations] || 0,
        axe_rule_results: rule_results,
        issues_total: rule_results.sum { |rule| rule[:status] == :violations ? rule[:nodes].count : 0 }
      }
    end

    def compute_found
      !data.nil?
    end

    def compute_conform
      compute_found && (passes + incomplete + violations).positive? && violations.zero?
    end

    def run_axe_check
      locale = File.read(AXE_LOCALE_PATH)
      script_tag = File.read(AXE_SOURCE_PATH)
      script = "axe.configure({locale: #{locale} }); axe.run(document, \
                { runOnly: { type: 'rule', values: #{RGAA_AXE_RULES} }, reporter: 'v2'}).then(results => __f(results))"

      Browser.run_script_on_html(audit.page_snapshots.find_by(kind: "home").html, script, script_tag)
    end

    def format_axe_rule_results(results)
      %w[violations passes incomplete inapplicable].flat_map do |status|
        (results[status] || []).map do |rule|
          {
            id: rule["id"],
            status: status.to_sym,
            impact: rule["impact"],
            description: rule["description"],
            help: rule["help"],
            help_url: rule["helpUrl"],
            nodes: (rule["nodes"] || []).map do |node|
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
end
