module AuditsHelper
  def obligation_badge(check)
    return [:error, t("shared.absent")] unless check.found?

    [check.conform? ? :success : :info, t("shared.present")]
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
    present ? [:success, t("shared.present")] : [:error, t("shared.absent")]
  end

  def validity_badge(check)
    return [:error, t("shared.absent")] unless check.found?

    conform = check.conform

    [conform ? :success : :warning, conform ? t("shared.valid") : t("shared.invalid")]
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

  def star_rating(filled:, total:, color:, label:)
    filled_star_count = filled.floor
    has_half_star = filled - filled_star_count >= 0.5

    tag.span(class: "star-rating star-rating--#{color}", role: "img", "aria-label": t("audits.show.rating_aria_label", label:, filled:, total:)) do
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
