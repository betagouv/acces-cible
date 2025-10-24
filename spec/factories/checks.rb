FactoryBot.define do
  factory :check do
    audit { association(:audit, :without_checks) }

    Check.types.each do |type, klass|
      trait(type) do
        initialize_with { klass.new(attributes) }
      end
    end

    # we could try and emulate the complete logic of going through the
    # chain of states (pending -> ready -> running, etc) but it would
    # require a lot of heavy machinery since Checks have requirements
    # + runtime logic (like running browser things). Instead, insert
    # the last transition as STATE and run with it: it might be
    # exactly the right kind of dumb we want for testing.
    CheckStateMachine.states.each do |state|
      trait(state) do
        after(:create) do |check, _eval|
          CheckTransition.create!(
            check:,
            to_state: state,
            most_recent: true,
            sort_key: 0
          )
        end
      end
    end

    trait :with_data do
      completed

      after(:build) do |check|
        current_year = Date.current.year
        check.data = case check
        when Checks::Reachable
          {}
        when Checks::LanguageIndication
          { indication: "fr-FR", detected_code: "fr" }
        when Checks::AccessibilityMention
          { mention: "totalement" }
        when Checks::FindAccessibilityPage
          { url: "https://example.com/accessibilite", title: "Déclaration d'accessibilité" }
        when Checks::AnalyzeAccessibilityPage
          {
            audit_date: 1.year.ago.to_date.to_s,
            audit_update_date: 6.months.ago.to_date.to_s,
            compliance_rate: 85.5,
            standard: "RGAA v4.1",
            auditor: "Acme Corp"
          }
        when Checks::AccessibilityPageHeading
          {
            page_headings: [
              [1, "Déclaration d'accessibilité"],
              [2, "État de conformité"],
              [3, "Résultats des tests"]
            ],
            comparison: [
              ["Déclaration d'accessibilité", 1, :ok, "Déclaration d'accessibilité"],
              ["État de conformité", 2, :ok, "État de conformité"],
              ["Résultats des tests", 3, :ok, "Résultats des tests"]
            ]
          }
        when Checks::AnalyzeSchema
          {
            link_url: "https://example.com/schema-pluriannuel.pdf",
            link_text: "Schéma pluriannuel #{current_year}-#{current_year + 2}",
            years: [current_year, current_year + 1, current_year + 2],
            reachable: true,
            valid_years: true
          }
        when Checks::AnalyzePlan
          {
            link_url: "https://example.com/plan-annuel-#{current_year}.pdf",
            link_text: "Plan annuel #{current_year}",
            years: [current_year],
            reachable: true,
            valid_year: true,
            page_heading: nil
          }
        when Checks::RunAxeOnHomepage
          {
            passes: 45,
            incomplete: 2,
            inapplicable: 10,
            violations: 3,
            violation_data: [
              {
                id: "color-contrast",
                impact: "serious",
                description: "Ensures the contrast between foreground and background colors meets WCAG 2 AA contrast ratio thresholds",
                help: "Elements must have sufficient color contrast",
                help_url: "https://dequeuniversity.com/rules/axe/4.4/color-contrast",
                nodes: [
                  {
                    html: "<p>Low contrast text</p>",
                    impact: "serious",
                    target: ["p"],
                    failure_summary: "Element has insufficient color contrast of 2.5:1"
                  }
                ]
              }
            ],
            issues_total: 5
          }
        else
          raise ArgumentError, "The #{check.type} factory needs to be implemented in #{__FILE__}"
        end
      end
    end
  end
end
