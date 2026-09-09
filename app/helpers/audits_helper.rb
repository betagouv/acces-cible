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

  def page_heading_levels(check)
    check.page_headings.to_h { |level, heading| [heading, level] }
  end

  def declaration_level_offset_notice(check)
    return if check.heading_offset.zero?

    section_level = check.heading_statuses.map(&:expected_level).min
    t("audits.headings.level_offset", expected: section_level, found: section_level + check.heading_offset)
  end

  def heading_severity(heading_status)
    case
    when heading_status.ok? then :success
    when heading_status.warning? then :warning
    else :error
    end
  end

  def heading_status_badge(heading_status)
    badge(status: heading_severity(heading_status), text: heading_status.message)
  end

  def found_level_badge(level)
    return muted_dash unless level

    badge(status: nil, text: "H#{level}", no_icon: true)
  end

  def expected_level_badge(heading_status, offset:)
    return muted_dash unless heading_status.missing? || heading_status.incorrect_level?

    badge(status: heading_severity(heading_status), text: "H#{heading_status.expected_level + offset}", no_icon: true)
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

  private

  def star_modifier_class(position, filled_star_count, has_half_star)
    if position < filled_star_count
      "filled"
    elsif position == filled_star_count && has_half_star
      "half-filled"
    end
  end
end
