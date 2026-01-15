module Checks
  class AnalyzeSchema < Check
    store_accessor :data, :link_url, :link_text, :link_misplaced, :years, :reachable, :valid_years, :text
    include AccessibilityDocumentAnalyzer

    PRIORITY = 23
    MAX_YEARS_VALIDITY = 3
    # Matches various forms of "schéma/schema" accessibility links:
    # - "schéma pluriannuel de/d' accessibilité (numérique)" or "schéma pluriannuel RGAA"
    # - "schéma annuel d'accessibilité"
    # - "schéma d'accessibilité numérique/pluriannuel"
    # - "accessibilité numérique — schéma annuel" (with various dash types)
    PATTERN = /
      (?:
        sch[eé]ma\s+
        (?:
          pluri-?annuel\s+(?:de\s+(?:mise\s+en\s+|l[''])?|d['’])accessibilit[eé](?:\s+num[eé]rique)?(?:\s+\d{4}(?:\s*[-–]\s*\d{4})?)?|
          pluri-?annuel\s+rgaa(?:\s+\d{4}(?:\s*[-–]\s*\d{4})?)?|
          annuel\s+d['’]accessibilit[eé](?:\s+\d{4}(?:\s*[-–]\s*\d{4})?)?|
          d['’]accessibilit[eé]\s+(?:num[eé]rique|pluri-?annuel)(?:\s+\d{4}(?:\s*[-–]\s*\d{4})?)?
        )|
        accessibilit[eé]\s+num[eé]rique\s+[—–-]\s+sch[eé]ma\s+annuel(?:\s+\d{4}(?:\s*[-–]\s*\d{4})?)?
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
        link_misplaced: link ? !link_between_headings? : nil,
        valid_years: within_three_years?(years),
        reachable: Browser.reachable?(link&.href),
        text: link ? nil : text_in_main
      }
    end

    def within_three_years?(years)
      return false if years.blank?
      return false if years.last - years.first > MAX_YEARS_VALIDITY

      Date.current.year.between?(years.first, years.last)
    end
  end
end
