module Checks
  class AnalyzeSchema < Check
    store_accessor :data, :link_url, :link_text, :link_misplaced, :years, :reachable, :valid_years, :text
    include AccessibilityDocumentAnalyzer

    PRIORITY = 23
    MAX_YEAR_GAP = 2
    # Matches various forms of "schéma/schema" accessibility links:
    # - "schéma pluriannuel de/d' accessibilité (numérique)" or "schéma pluriannuel RGAA"
    # - "schéma annuel d'accessibilité"
    # - "schéma d'accessibilité numérique/pluriannuel"
    # - "accessibilité numérique — schéma annuel" (with various dash types)
    PATTERN = /
      (?:
        sch[eé]ma\s+
        (?:
          pluri-?annuel\s+\d{4}(?:\s*[-–]\s*\d{4})?|
          pluri-?annuel\s+(?:de\s+(?:mise\s+en\s+|l[''])?|d['’])accessibilit[eé](?:\s+num[eé]rique)?(?:\s+\d{4}(?:\s*[-–]\s*\d{4})?)?|
          pluri-?annuel\s+rgaa(?:\s+\d{4}(?:\s*[-–]\s*\d{4})?)?|
          annuel\s+d['’]accessibilit[eé](?:\s+\d{4}(?:\s*[-–]\s*\d{4})?)?|
          d['’]accessibilit[eé]\s+(?:num[eé]rique|pluri-?annuel)(?:\s+\d{4}(?:\s*[-–]\s*\d{4})?)?
        )|
        accessibilit[eé]\s+num[eé]rique\s+[—–-]\s+sch[eé]ma\s+annuel(?:\s+\d{4}(?:\s*[-–]\s*\d{4})?)?
      )
    /xi

    private

    def within_range?(years)
      return false if years.blank?
      return false if years.last - years.first > MAX_YEAR_GAP

      Date.current.year.between?(years.first, years.last)
    end
  end
end
