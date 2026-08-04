class BackfillChecksConformAndPresent < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    Check.in_batches.update_all(found: false, conform: false)

    # reachable — found == conform.
    Checks::Reachable.where.not(data: nil).in_batches.update_all(found: true, conform: true)

    # find_accessibility_page — found = page found, conform = page is internal
    with_url = Checks::FindAccessibilityPage.where("data ->> 'url' IS NOT NULL")
    with_url.in_batches.update_all(found: true)
    with_url.where("data ->> 'internal' = 'true'").in_batches.update_all(conform: true)

    # accessibility_mention — any level is found and conform
    Checks::AccessibilityMention.where("data ->> 'mention' IS NOT NULL")
                                .in_batches.update_all(found: true, conform: true)

    # analyze_accessibility_page — found = analyzed, conform = requirements found
    analyzed = Checks::AnalyzeAccessibilityPage.where.not(data: nil)
    analyzed.in_batches.update_all(found: true)
    analyzed.where(
      "data ->> 'audit_date' IS NOT NULL AND data ->> 'compliance_rate' IS NOT NULL " \
        "AND (data ->> 'mentions_article')::boolean IS TRUE"
    ).in_batches.update_all(conform: true)

    # analyze_schema / analyze_plan — found = document found, conform = valid_years
    [Checks::AnalyzeSchema, Checks::AnalyzePlan].each do |klass|
      docs = klass.where("data ->> 'link_url' IS NOT NULL OR data ->> 'text' IS NOT NULL")
      docs.in_batches.update_all(found: true)
      docs.where("(data ->> 'valid_years')::boolean IS TRUE AND (data ->> 'text') IS NULL").in_batches.update_all(conform: true)
    end

    # language_indication - we won't use the DCL gem here
    Checks::LanguageIndication.where("data ->> 'indication' IS NOT NULL").find_each do |check|
      conform = check.data["indication"].downcase.include?("fr")

      check.update_columns(found: true, conform:)
    end

    # accessibility_page_heading — conform = score >= 90
    Checks::AccessibilityPageHeading.where("data ->> 'comparison' IS NOT NULL").find_each do |check|
      comparison = check.data["comparison"]
      points = comparison.sum do |(_, _, status, _)|
        case status
        when "ok" then 1
        when "incorrect_order", "incorrect_level" then 0.5
        else 0
        end
      end
      score = points / comparison.size.to_f * 100

      check.update_columns(found: true, conform: score >= 90)
    end

    # run_axe_on_homepage — store derived scalars, conform = fully conform
    Checks::RunAxeOnHomepage.where.not(data: nil).find_each do |check|
      passes, incomplete, violations = check.data.values_at("passes", "incomplete", "violations").map(&:to_i)
      applicable = passes + incomplete + violations
      success_rate = applicable.zero? ? nil : ((passes + incomplete) / applicable.to_f * 100).round(2)

      check.update_columns(
        found: true,
        conform: success_rate == 100.0,
      )
    end
  end

  def down
    Check.in_batches.update_all(found: nil, conform: nil)
  end
end
