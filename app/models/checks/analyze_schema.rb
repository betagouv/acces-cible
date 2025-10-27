module Checks
  class AnalyzeSchema < Check
    PRIORITY = 23
    REQUIREMENTS = Check::REQUIREMENTS + [:find_accessibility_page]
    MAX_YEARS_VALIDITY = 3
    # Matches various forms of "schéma/schema" accessibility links:
    # - "schéma pluriannuel de/d' accessibilité (numérique)" or "schéma pluriannuel RGAA"
    # - "schéma annuel d'accessibilité"
    # - "schéma d'accessibilité numérique/pluriannuel"
    # - "accessibilité numérique — schéma annuel" (with various dash types)
    SCHEMA_PATTERN = /
      sch[eé]ma\s+
      (?:
        pluri-?annuel\s+(?:de\s+(?:mise\s+en\s+|l['’])?|d['’])accessibilit[eé](?:\s+num[eé]rique)?|
        pluri-?annuel\s+rgaa|
        annuel\s+d['’]accessibilit[eé]|
        d['’]accessibilit[eé]\s+(?:num[eé]rique|pluri-?annuel)
      )|
      accessibilit[eé]\s+num[eé]rique\s+[—–-]\s+sch[eé]ma\s+annuel
    /xi

    store_accessor :data, :link_url, :link_text, :link_misplaced, :years, :reachable, :valid_years, :page_heading

    def find_link
      return unless page

      page.links(skip_files: false, scope: :main)
        .select { |link| link.text.match? SCHEMA_PATTERN }
        .max_by { |link| extract_years(link.text) }
    end

    def link_between_headings?
      return unless page

      page.links(skip_files: false, scope: :main, between_headings: [:previous, "État de conformité"])
        .select { |link| link.text.match? SCHEMA_PATTERN }
        .max_by { |link| extract_years(link.text) }
    end

    def find_page_heading
      return unless page

      page.headings.find do |heading|
        heading.match? SCHEMA_PATTERN
      end
    end

    def all_passed? = link_url && valid_years && reachable
    def valid_link? = link_url && reachable

    def custom_badge_status
      if all_passed?
        :success
      elsif valid_link? || page_heading
        :warning
      else
        :error
      end
    end

    def custom_badge_text
      if all_passed?
        human(:all_passed)
      elsif valid_link?
        human(:invalid_years)
      elsif page_heading
        human(:schema_in_page_heading)
      else
        human(:link_not_found)
      end
    end

    alias custom_badge_link link_url

    private

    def analyze!
      link = find_link
      page_heading = find_page_heading unless link
      source_text = link&.text || link&.href || page_heading
      return unless source_text

      years = extract_years(source_text)
      {
        years:,
        link_url: link&.href,
        link_text: link&.text,
        link_misplaced: link ? !link_between_headings? : nil,
        valid_years: validate_years(years),
        reachable: Browser.reachable?(link&.href),
        page_heading:
      }
    end

    def page = @page ||= audit.page(:accessibility)
    def extract_years(string) = string.to_s.scan(/\d{4}/).map(&:to_i).sort
    def validate_years(years) = years.size.in?(1..MAX_YEARS_VALIDITY) && years.first.upto(years.last).include?(Date.current.year)
  end
end
