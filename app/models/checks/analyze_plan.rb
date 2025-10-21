module Checks
  class AnalyzePlan < Check
    PRIORITY = 24
    REQUIREMENTS = Check::REQUIREMENTS + [:find_accessibility_page]
    PLAN_PATTERN = /
      plan\s+
      (?:
        annuel(?:\s+d['’]accessibilit[eé](?:\s+num[eé]rique)?|\s+\d{4})|
        d['’]action(?:s)?
      )
    /xi

    store_accessor :data, :link_url, :link_text, :years, :reachable, :valid_year, :page_heading

    def find_link
      return unless page

      page.links(skip_files: false, scope: :main, between: [
        :previous,
        fuzzy_match_for("État de conformité")
      ])
        .select { |link| link.text.match? PLAN_PATTERN }
        .max_by { |link| extract_years(link.text) }
    end

    def find_page_heading
      return unless page

      page.headings.find do |heading|
        heading.match? PLAN_PATTERN
      end
    end

    def all_passed? = link_url && valid_year && reachable
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
        human(:invalid_year)
      elsif page_heading
        human(:plan_in_page_heading)
      else
        human(:link_not_found)
      end
    end

    alias custom_badge_link link_url

    private

    def analyze!
      link = find_link
      page_heading = find_page_heading unless link
      return unless link || page_heading

      years = if link
        extract_years(link.text) || extract_years(link.href)
      else
        extract_years(page_heading)
      end
      {
        years:,
        link_url: link&.href,
        link_text: link&.text,
        valid_year: validate_year(years.last),
        reachable: Browser.exists?(link&.href),
        page_heading:
      }
    end

    def page = @page ||= audit.page(:accessibility)
    def extract_years(string) = string.to_s.scan(/\d{4}/).map(&:to_i).sort

    def validate_year(year)
      valid_years = Date.current.year.then { |current_year| (current_year - 1)..(current_year + 1) }
      valid_years.include?(year)
    end
  end
end
