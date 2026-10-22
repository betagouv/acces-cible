module AuditColumns
  extend CheckHelper

  GROUPS = {
    main_results: %w[compliance_rate declared_level legal_obligations declaration_quality],
    legal_obligations: %w[accessibility_page accessibility_mention schema plan],
    meta: %w[reachable evaluator organization_label tags],
    declaration_quality: %w[declaration_date standard auditor law_article contact_email contact_form declaration_format schema_quality plan_quality],
    automated_tests: %w[automated_tests_result automated_tests_applicable automated_tests_passed automated_tests_inapplicable],
  }.freeze
  DEFAULT = %w[compliance_rate declared_level legal_obligations declaration_quality evaluator organization_label tags].freeze
  EXPORT = %w[
    site evaluated_url reachable redirected redirect_url
    accessibility_page declaration_url declaration_hosting
    compliance_rate_evaluation compliance_rate accessibility_mention declared_level
    schema schema_url schema_quality
    plan plan_url plan_quality
    declaration_date_evaluation declaration_date standard_evaluation standard auditor_evaluation auditor
    law_article contact_evaluation contact_email contact_form declaration_format
    legal_obligations declaration_quality
    automated_tests_result automated_tests_applicable automated_tests_passed automated_tests_inapplicable
    evaluator organization_label tags last_audit_at audit_url
  ].freeze
  DASH = I18n.t("shared.dash")

  class << self
    def value(audit, column)
      from_checks(audit, column).presence || DASH
    end

    def from_checks(audit, column)
      accessibility_page = audit.find_accessibility_page
      mention = audit.accessibility_mention
      accessibility_analysis = audit.analyze_accessibility_page
      heading = audit.accessibility_page_heading
      schema = audit.analyze_schema
      plan = audit.analyze_plan
      axe = audit.run_axe_on_homepage
      contact = accessibility_analysis.contact_email.presence || accessibility_analysis.contact_form

      case column
      when "accessibility_mention" then obligation(mention) if mention.completed?
      when "accessibility_page" then obligation(accessibility_page) unless accessibility_page.aborted?
      when "audit_url" then Rails.application.routes.url_helpers.site_audit_url(audit.site, audit)
      when "auditor" then accessibility_analysis.auditor
      when "auditor_evaluation" then presence(accessibility_analysis.auditor.present?) if accessibility_analysis.completed?
      when "automated_tests_applicable" then axe.applicable_total
      when "automated_tests_inapplicable" then axe.inapplicable
      when "automated_tests_passed" then axe.passes
      when "automated_tests_result" then I18n.t("audits.show.automated_tests_results", count: axe.passes, total: axe.applicable_total) if axe.completed?
      when "compliance_rate" then accessibility_analysis.human_compliance_rate
      when "compliance_rate_evaluation" then presence(accessibility_analysis.compliance_rate.present?) if accessibility_analysis.completed?
      when "contact_email" then accessibility_analysis.contact_email
      when "contact_evaluation" then presence(contact.present?) if accessibility_analysis.completed?
      when "contact_form" then accessibility_analysis.contact_form
      when "declaration_date" then accessibility_analysis.audit_date && I18n.l(accessibility_analysis.audit_date)
      when "declaration_date_evaluation" then presence(accessibility_analysis.audit_date.present?) if accessibility_analysis.completed?
      when "declaration_format" then validity(heading.conform) if heading.completed?
      when "declaration_hosting" then validity(accessibility_page.conform) if accessibility_page.found?
      when "declaration_quality" then audit.declaration_quality_score.to_f if accessibility_page.found?
      when "declaration_url" then accessibility_page.url
      when "declared_level" then check_status(mention) if mention.found
      when "evaluated_url" then audit.site.url
      when "evaluator" then audit.user.to_s
      when "last_audit_at" then I18n.l(audit.created_at.in_time_zone, format: :complete)
      when "law_article" then presence(accessibility_analysis.mentions_article) if accessibility_analysis.completed?
      when "legal_obligations" then audit.legal_obligation_score.to_i if accessibility_page.found?
      when "organization_label" then audit.user.team.organization_label
      when "plan" then obligation(plan) if accessibility_page.found?
      when "plan_quality" then validity(plan.conform) if plan.found
      when "plan_url" then plan.link_url
      when "reachable" then yes_no(audit.reachable.found?)
      when "redirect_url" then audit.reachable.redirect_url
      when "redirected" then yes_no(audit.reachable.redirected?)
      when "schema" then obligation(schema) if accessibility_page.found?
      when "schema_quality" then validity(schema.conform) if schema.found
      when "schema_url" then schema.link_url
      when "site" then audit.site.normalized_url
      when "standard" then accessibility_analysis.standard
      when "standard_evaluation" then presence(accessibility_analysis.standard.present?) if accessibility_analysis.completed?
      when "tags" then audit.site.tags_list
      else DASH
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

    def yes_no(answer)
      { status: answer ? :success : :error, text: I18n.t(answer ? "shared.yes" : "shared.no"), no_icon: true }
    end

    def validity(valid)
      valid ? { status: :success, text: I18n.t("shared.valid") } : { status: :warning, text: I18n.t("shared.invalid") }
    end
  end
end
