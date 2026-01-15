module Checks
  class AnalyzeSchema < Check
    PRIORITY = 23
    REQUIREMENTS = Check::REQUIREMENTS + [:find_accessibility_page]
    MAX_YEARS_VALIDITY = 3
    YEAR_PATTERN = /\d{4}/
    # Matches various forms of "schéma/schema" accessibility links:
    # - "schéma pluriannuel de/d' accessibilité (numérique)" or "schéma pluriannuel RGAA"
    # - "schéma annuel d'accessibilité"
    # - "schéma d'accessibilité numérique/pluriannuel"
    # - "accessibilité numérique — schéma annuel" (with various dash types)
    SCHEMA_PATTERN = /
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

    store_accessor :data, :link_url, :link_text, :link_misplaced, :years, :reachable, :valid_years, :text

    def find_link
      return unless page

      page.links(skip_files: false, scope: :main)
          .select { |link| link.text.match? SCHEMA_PATTERN }
          .max_by { |link| extract_valid_years(link.text) }
    end

    def link_between_headings?
      return unless page

      page.links(skip_files: false, scope: :main, between_headings: [:previous, "État de conformité"])
          .select { |link| link.text.match? SCHEMA_PATTERN }
          .max_by { |link| extract_valid_years(link.text) }
    end

    def find_text_in_main
      return unless page

      page.text(scope: :main)
          .scan(SCHEMA_PATTERN)
          .flatten
          .compact
          .max_by { |match| extract_valid_years(match) }
    end

    def all_passed?
      link_url && valid_years && reachable
    end

    def valid_link?
      link_url && reachable
    end

    def custom_badge_status
      if all_passed?
        :success
      elsif valid_link? || text
        :warning
      else
        :error
      end
    end

    def custom_badge_text
      if all_passed?
        t("checks.analyze_schema.all_passed")
      elsif valid_link?
        years.present? ? t("checks.analyze_schema.invalid_years") : t("checks.analyze_schema.years_not_found")
      elsif text
        t("checks.analyze_schema.schema_in_main_text")
      else
        t("checks.analyze_schema.link_not_found")
      end
    end

    alias custom_badge_link link_url

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

    def page
      @page ||= audit.page(:accessibility)
    end

    def extract_valid_years(*sources)
      result = sources
        .compact
        .find do |source|
        years = source.to_s.scan(YEAR_PATTERN).map(&:to_i).uniq.sort

        return years if within_three_years?(years)
      end

      result || []
    end

    def within_three_years?(years)
      return false if years.blank?
      return false if years.last - years.first > MAX_YEARS_VALIDITY

      Date.current.year.between?(years.first, years.last)
    end
  end
end
