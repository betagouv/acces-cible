module OneOff
  class BackfillChecksConformAndFoundJob < ApplicationJob
    limits_concurrency key: :backfill_checks_conform_and_found

    def perform(audit_ids)
      # reachable — found == conform.
      Checks::Reachable.where(audit_id: audit_ids).where.not(data: nil).update_all(found: true, conform: true)

      # find_accessibility_page — found = page found, conform = page is internal
      Checks::FindAccessibilityPage.where(audit_id: audit_ids).where("data ->> 'url' IS NOT NULL")
                                   .update_all("found = true, conform = COALESCE(data ->> 'internal' = 'true', false)")

      # accessibility_mention — any level is found and conform
      Checks::AccessibilityMention.where(audit_id: audit_ids).where("data ->> 'mention' IS NOT NULL")
                                  .update_all(found: true, conform: true)

      # analyze_accessibility_page — found = analyzed, conform = requirements found
      Checks::AnalyzeAccessibilityPage.where(audit_id: audit_ids).where.not(data: nil).update_all(<<~SQL.squish)
        found = true,
        conform = (
          data ->> 'audit_date' IS NOT NULL AND data ->> 'compliance_rate' IS NOT NULL
          AND (data ->> 'mentions_article')::boolean IS TRUE
        )
      SQL

      # analyze_schema / analyze_plan — found = document found, conform = valid_years
      [Checks::AnalyzeSchema, Checks::AnalyzePlan].each do |klass|
        klass.where(audit_id: audit_ids).where("data ->> 'link_url' IS NOT NULL OR data ->> 'text' IS NOT NULL")
             .update_all(<<~SQL.squish)
               found = true,
               conform = (
                 (data ->> 'valid_years')::boolean IS TRUE
                 AND (data ->> 'text') IS NULL
                 AND (data ->> 'reachable')::boolean IS true
               )
             SQL
      end

      # language_indication - we won't use the DCL gem here
      Checks::LanguageIndication.where(audit_id: audit_ids).where("data ->> 'indication' IS NOT NULL")
                                .pluck(:id, :data)
                                .group_by { |_id, data| ["fr", data["detected_code"].downcase].join.include?(data["indication"].downcase) }
                                .each { |conform, rows| Check.where(id: rows.map(&:first)).update_all(found: true, conform:) }

      # accessibility_page_heading — conform = score >= 90
      Checks::AccessibilityPageHeading.where(audit_id: audit_ids).where("data ->> 'comparison' IS NOT NULL")
                                      .pluck(:id, :data)
                                      .group_by { |_id, data| accessibility_page_heading_score(data) >= 90 }
                                      .each { |conform, rows| Check.where(id: rows.map(&:first)).update_all(found: true, conform:) }

      # run_axe_on_homepage — conform = fully conform
      Checks::RunAxeOnHomepage.where(audit_id: audit_ids).where.not(data: nil)
                              .pluck(:id, :data)
                              .group_by { |_id, data| run_axe_success_rate(data) == 100.0 }
                              .each { |conform, rows| Check.where(id: rows.map(&:first)).update_all(found: true, conform:) }
    end

    private

    def accessibility_page_heading_score(data)
      comparison = data["comparison"]
      points = comparison.sum do |(_, _, status, _)|
        case status
        when "ok" then 1
        when "incorrect_order", "incorrect_level" then 0.5
        else 0
        end
      end

      points / comparison.size.to_f * 100
    end

    def run_axe_success_rate(data)
      passes, incomplete, violations = data.values_at("passes", "incomplete", "violations").map(&:to_i)
      applicable = passes + incomplete + violations

      applicable.zero? ? nil : ((passes + incomplete) / applicable.to_f * 100).round(2)
    end
  end
end
