module AuditColumns
  extend CheckHelper

  GROUPS = {
    main_results: %w[compliance_rate declared_level legal_obligations declaration_quality],
    legal_obligations: %w[accessibility_page accessibility_mention schema plan],
    meta: %w[reachable evaluator organization_label tags],
    declaration_quality: %w[declaration_hosting declaration_date standard auditor law_article contact declaration_format schema_quality plan_quality],
    automated_tests: %w[automated_tests_result automated_tests_applicable automated_tests_passed automated_tests_inapplicable],
  }.freeze
  DEFAULT = %w[compliance_rate declared_level legal_obligations declaration_quality evaluator organization_label tags].freeze
  ALL = ["site", *GROUPS.values.flatten, "last_audit_at"].freeze

  class << self
    def value(audit, column)
      declaration = audit.analyze_accessibility_page
      axe = audit.run_axe_on_homepage

      case column
      when "accessibility_mention" then obligation(audit.accessibility_mention)
      when "accessibility_page" then obligation(audit.find_accessibility_page)
      when "auditor" then validity(declaration.auditor.present?)
      when "automated_tests_applicable" then axe.applicable_total || check_status(axe)
      when "automated_tests_inapplicable" then axe.inapplicable || check_status(axe)
      when "automated_tests_passed" then axe.passes || check_status(axe)
      when "automated_tests_result" then axe.completed? ? I18n.t("audits.show.automated_tests_results", count: axe.passes, total: axe.applicable_total) : check_status(axe)
      when "compliance_rate" then declaration.human_compliance_rate || check_status(declaration)
      when "contact" then validity(declaration.contact_email.present? || declaration.contact_form.present?)
      when "declaration_date" then validity(declaration.audit_date.present?)
      when "declaration_format" then validity(audit.accessibility_page_heading.conform)
      when "declaration_hosting" then validity(audit.find_accessibility_page.conform)
      when "declaration_quality" then audit.declaration_quality_score.to_f
      when "declared_level" then check_status(audit.accessibility_mention)
      when "evaluator" then audit.user.to_s
      when "last_audit_at" then I18n.l(audit.created_at.in_time_zone.to_date)
      when "law_article" then validity(declaration.mentions_article)
      when "legal_obligations" then audit.legal_obligation_score.to_i
      when "organization_label" then audit.user.team.organization_label
      when "plan" then obligation(audit.analyze_plan)
      when "plan_quality" then validity(audit.analyze_plan.conform)
      when "reachable" then check_status(audit.reachable)
      when "schema" then obligation(audit.analyze_schema)
      when "schema_quality" then validity(audit.analyze_schema.conform)
      when "site" then audit.site.normalized_url
      when "standard" then validity(declaration.standard.present?)
      when "tags" then audit.site.tags_list
      else
        "-"
      end
    end

    def check_status(check)
      { status: status_to_badge_level(check), text: status_to_badge_text(check), no_icon: true }
    end

    def obligation(check)
      return presence(false) unless check.found?

      { status: check.conform? ? :success : :info, text: I18n.t("shared.present") }
    end

    def presence(present)
      present ? { status: :success, text: I18n.t("shared.present") } : { status: :error, text: I18n.t("shared.absent") }
    end

    def validity(valid)
      valid ? { status: :success, text: I18n.t("shared.valid") } : { status: :warning, text: I18n.t("shared.invalid") }
    end
  end
end
