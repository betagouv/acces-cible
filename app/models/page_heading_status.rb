require_relative "../libs/string_comparison" # Autoload seems to fail from within a Data class

class PageHeadingStatus < Data.define(:expected_heading, :expected_level, :status, :actual_heading)
  SIMILARITY_THRESHOLD = 0.9

  delegate :inquiry, to: :status, prefix: true
  delegate :ok?, :missing?, :incorrect_order?, :incorrect_level?, to: :status_inquiry

  def warning?
    incorrect_order? || incorrect_level?
  end

  def error?
    !ok?
  end

  def message
    I18n.t("checks.accessibility_page_heading.statuses.#{status}")
  end

  def fuzzy_match?
    actual_heading &&
      StringComparison.similarity_ratio(expected_heading, actual_heading, ignore_case: true) < SIMILARITY_THRESHOLD
  end
end
