module Checks
  class AnalyzePlan < Check
    PRIORITY = 24
    REQUIREMENTS = Check::REQUIREMENTS + [:find_accessibility_page]
    MAX_YEARS_VALIDITY = 3
    LINK_PATTERN = /
      plan\s+
      (?:
        annuel(?:\s+d['’]accessibilit[eé](?:\s+num[eé]rique)?|\s+\d{4})|
        d['’]action(?:s)?
      )
    /xi

    store_accessor :data, :link_url, :link_text, :year, :reachable, :valid_year

    def find_link
      return unless page

      page.links(skip_files: false)
        .select { |link| link.text.match? LINK_PATTERN }
        .max_by { |link| extract_year(link.text) }
    end

    def all_passed? = link_url && valid_year && reachable
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
        human(:invalid_year)
      else
        human(:link_not_found)
      end
    end

    alias custom_badge_link link_url

    private

    def analyze!
      return unless link = find_link

      year = extract_year(link.text)
      {
        year:,
        link_url: link.href,
        link_text: link.text,
        valid_year: validate_year(year),
        reachable: reachable?(link.href)
      }
    end

    def page = @page ||= audit.page(:accessibility)
    def extract_year(string) = string.to_s.scan(/\d{4}/).map(&:to_i).sort.last

    def validate_year(year)
      current_year = Date.current.year
      valid_years = (current_year - MAX_YEARS_VALIDITY).upto(current_year)
      valid_years.include?(year)
    end

    def reachable?(url) = url && Browser.get(url)[:status] == Rack::Utils::SYMBOL_TO_STATUS_CODE[:ok]
  end
end
