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
    LINK_PATTERN = /
      sch[eé]ma\s+
      (?:
        pluri-?annuel\s+(?:de\s+(?:mise\s+en\s+|l['’])?|d['’])accessibilit[eé](?:\s+num[eé]rique)?|
        pluri-?annuel\s+rgaa|
        annuel\s+d['’]accessibilit[eé]|
        d['’]accessibilit[eé]\s+(?:num[eé]rique|pluri-?annuel)
      )|
      accessibilit[eé]\s+num[eé]rique\s+[—–-]\s+sch[eé]ma\s+annuel
    /xi

    store_accessor :data, :link_url, :link_text, :years, :reachable, :valid_years

    def find_link
      return unless page

      page.links(skip_files: false, scope: :main)
        .select { |link| link.text.match? LINK_PATTERN }
        .max_by { |link| extract_years(link.text) }
    end

    def all_passed? = link_url && valid_years && reachable
    def valid_link? = link_url && reachable

    def custom_badge_status
      if all_passed?
        :success
      elsif valid_link?
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
      else
        human(:link_not_found)
      end
    end

    alias custom_badge_link link_url

    private

    def analyze!
      return unless link = find_link

      years = extract_years(link.text)
      {
        years:,
        link_url: link.href,
        link_text: link.text,
        valid_years: validate_years(years),
        reachable: Browser.exists?(link.href)
      }
    end

    def page = @page ||= audit.page(:accessibility)
    def extract_years(string) = string.to_s.scan(/\d{4}/).map(&:to_i).sort
    def validate_years(years) = years.size.in?(1..3) && years.first.upto(years.last).include?(Date.current.year)
  end
end
