module OneOff
  class BackfillAuditsScoresJob < ApplicationJob
    limits_concurrency key: :backfill_audits_scores

    def perform(ids)
      Audit.where(id: ids).includes(:checks).find_each do |audit|
        audit.update_columns(
          legal_obligation_score: compute_legal_obligation_score(audit),
          declaration_quality_score: compute_declaration_quality_score(audit)
        )
      end
    end

    private

    def compute_legal_obligation_score(audit)
      legal_obligation_checks = %i[analyze_accessibility_page accessibility_mention analyze_schema analyze_plan]

      legal_obligation_checks.count { |check| audit.send(check).found }
    end

    def compute_declaration_quality_score(audit)
      declaration = audit.analyze_accessibility_page&.data || {}

      criteria = [
        declaration["audit_date"].present?,
        declaration["standard"].present?,
        declaration["auditor"].present?,
        declaration["mentions_article"].present?,
        declaration["contact_email"].present? || declaration["contact_form"].present?,
        audit.accessibility_page_heading&.conform,
        audit.analyze_schema&.conform,
        audit.analyze_plan&.conform
      ]

      criteria.count { it } * 0.5
    end
  end
end
