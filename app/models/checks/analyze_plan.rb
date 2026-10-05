module Checks
  class AnalyzePlan < Check
    store_accessor :data, :link_url, :link_text, :link_misplaced, :years, :reachable, :valid_years, :text
    include AccessibilityDocumentAnalyzer

    PRIORITY = 24
    PATTERN = /
      plan\s+
      (?:
        annuel\s+(?:de\s+mise\s+en\s+|d['’])?accessibilit[eé](?:\s+num[eé]rique)?(?:\s+\d{4}(?:\s*[-–]\s*\d{4})?)?|
        annuel\s+\d{4}(?:\s*[-–]\s*\d{4})?|
        (?:\d{4}\s+)?d['’]action(?:s)?(?:\s+\d{4}(?:\s*[-–]\s*\d{4})?)?
      )
    /xi

    private

    def analyze!
      link = find_link
      text_in_main = find_text_in_main
      return unless link || text_in_main

      years = extract_valid_years(link&.text, link&.href, text_in_main)

      {
        years:,
        link_url: link&.href,
        link_text: link&.text,
        link_misplaced: link ? !link_between_headings : nil,
        valid_years: within_three_years?(years),
        reachable: Browser.reachable?(link&.href),
        text: link ? nil : text_in_main
      }
    end

    def within_three_years?(years)
      return false if years.blank?
      current_year = Date.current.year

      return years.first == current_year if years.size == 1

      years.last.between?(current_year - 1, current_year + 1)
    end
  end
end
