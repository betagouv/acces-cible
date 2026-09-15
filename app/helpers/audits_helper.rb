module AuditsHelper
  def obligation_badge(check)
    return badge(status: :error, text: t("shared.absent")) unless check.found?

    badge(status: check.conform? ? :success : :info, text: t("shared.present"))
  end

  def obligation_comment(check)
    return if check.conform? || !check.found?

    case check
    when Checks::FindAccessibilityPage then t("checks.find_accessibility_page.external_explanation")
    when Checks::AnalyzeSchema then t("checks.analyze_schema.in_main_text")
    when Checks::AnalyzePlan then t("checks.analyze_plan.in_main_text")
    else
      muted_dash
    end
  end

  def obligation_value(check)
    case check
    when Checks::FindAccessibilityPage
      return muted_dash unless check.found?

      external_link_to(check.url, t("checks.find_accessibility_page.link_to_page"))
    when Checks::AccessibilityMention
      check.found? ? "« #{check.mention_text} »" : muted_dash
    when Checks::AnalyzeSchema, Checks::AnalyzePlan
      if check.link_url.present?
        external_link_to(check.link_url, check.link_text.presence || check.link_url)
      else
        check.text.presence || muted_dash
      end
    else
      muted_dash
    end
  end

  def presence_badge(present)
    present ? badge(status: :success, text: t("shared.present")) : badge(status: :error, text: t("shared.absent"))
  end

  def validity_badge(check)
    return badge(status: :error, text: t("shared.absent")) unless check.found?

    conform = check.conform

    badge(status: conform ? :success : :warning, text: conform ? t("shared.valid") : t("shared.invalid"))
  end

  def validity_comment(check)
    return nil if check.valid_years || !check.found?

    case check
    when Checks::AnalyzeSchema then t("checks.analyze_schema.invalid_years")
    when Checks::AnalyzePlan then t("checks.analyze_plan.invalid_years")
    else
      muted_dash
    end
  end

  def automated_test_status_badge(automated_test_result)
    status = automated_test_result[:status]
    label = t("audits.show.status_#{status}")

    case status
    when :violations then dsfr_badge(status: :error, html_attributes: { class: "fr-badge--sm fr-mb-0" }) { label }
    when :passes then dsfr_badge(status: :success, html_attributes: { class: "fr-badge--sm fr-mb-0" }) { label }
    else tag.p(label, class: "fr-badge fr-badge--sm fr-badge--no-icon fr-mb-0")
    end
  end

  def results_bar_segment_widths(counts_by_status, total_count)
    return {} if total_count.zero?

    counts_by_status.transform_values { |count| (count.fdiv(total_count) * 20).round * 5 }
  end

  def star_rating(filled:, total:, color:, label:, size: :m)
    filled_star_count = filled.floor
    has_half_star = filled - filled_star_count >= 0.5

    tag.span(class: "star-rating star-rating--#{color} star-rating--#{size}", role: "img", "aria-label": t("audits.show.rating_aria_label", label:, filled:, total:)) do
      safe_join(Array.new(total) { |position| tag.i("★", class: star_modifier_class(position, filled_star_count, has_half_star)) })
    end
  end

  def audit_cell(audit, column)
    case column
    when "evaluator" then tag.td(audit.user.to_s)
    when "organization_label" then tag.td(audit.team.organization_label)
    when "last_audit_at" then tag.td(audit_date_link(audit))
    when "tags" then tag.td(site_tags(audit.site), class: "fr-cell--multiline")
    else tag.td(audit_cell_content(audit, column), class: "fr-cell--center")
    end
  end

  private

  def audit_cell_content(audit, column)
    declaration = audit.analyze_accessibility_page
    axe = audit.run_axe_on_homepage

    case column
    when "compliance_rate" then declaration.human_compliance_rate || check_badge(declaration, hover: false, no_icon: true)
    when "declared_level" then check_badge(audit.accessibility_mention, hover: false, no_icon: true)
    when "legal_obligations" then star_rating(filled: audit.legal_obligation_score.to_i, total: 4, color: "blue", label: t("audits.audit.legal_obligations"))
    when "declaration_quality" then star_rating(filled: audit.declaration_quality_score.to_f, total: 4, color: "gold", label: t("audits.audit.declaration_quality"))
    when "accessibility_page" then obligation_badge(audit.find_accessibility_page)
    when "accessibility_mention" then obligation_badge(audit.accessibility_mention)
    when "schema" then obligation_badge(audit.analyze_schema)
    when "plan" then obligation_badge(audit.analyze_plan)
    when "declaration_date" then presence_badge(declaration.audit_date.present?)
    when "standard" then presence_badge(declaration.standard.present?)
    when "auditor" then presence_badge(declaration.auditor.present?)
    when "law_article" then presence_badge(declaration.mentions_article)
    when "contact" then presence_badge(declaration.contact_email.present? || declaration.contact_form.present?)
    when "declaration_format" then validity_badge(audit.accessibility_page_heading)
    when "schema_quality" then validity_badge(audit.analyze_schema)
    when "plan_quality" then validity_badge(audit.analyze_plan)
    when "automated_tests_result" then axe.completed? ? t("audits.show.automated_tests_results", count: axe.passes, total: axe.applicable_total) : muted_dash
    when "automated_tests_applicable" then axe.applicable_total || muted_dash
    when "automated_tests_passed" then axe.passes || muted_dash
    when "automated_tests_inapplicable" then axe.inapplicable || muted_dash
    when "reachable" then check_badge(audit.reachable, hover: false, no_icon: true)
    end
  end

  def audit_date_link(audit)
    local_time = audit.created_at.in_time_zone
    date = l(local_time.to_date)

    link_to site_audit_path(audit.site, audit), class: "fr-link ac-row-link__stretched", "aria-label": t("audits.audit.audit_label", url: audit.site.normalized_url, date:) do
      time_tag local_time, date, title: l(local_time, format: :long)
    end
  end

  def site_tags(site)
    names = site.tags.collect(&:name)

    safe_join([
                *names.take(3).map { dsfr_tag(title: it.truncate(ApplicationHelper::TRUNCATION_LENGTH), size: :sm) },
                (dsfr_tooltip(t("shared.x_more", x: names.size - 3), type: :link, title: names[3..].to_sentence) if names.size > 3)
              ])
  end

  def star_modifier_class(position, filled_star_count, has_half_star)
    if position < filled_star_count
      "filled"
    elsif position == filled_star_count && has_half_star
      "half-filled"
    end
  end
end
