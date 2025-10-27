module Checks
  class AnalyzePlan < Check
    PRIORITY = 24
    REQUIREMENTS = Check::REQUIREMENTS + [:find_accessibility_page]
    PLAN_PATTERN = /
      plan\s+
      (?:
        annuel\s+(?:d['’]accessibilit[eé](?:\s+num[eé]rique)?(?:\s+\d{4}(?:\s*[-–]\s*\d{4})?)?|\d{4}(?:\s*[-–]\s*\d{4})?)|
        (?:\d{4}\s+)?d['’]action(?:s)?(?:\s+\d{4}(?:\s*[-–]\s*\d{4})?)?
      )
    /xi

    store_accessor :data, :link_url, :link_text, :link_misplaced, :years, :reachable, :valid_year, :text

    def find_link
      return unless page

      page.links(skip_files: false, scope: :main)
        .select { |link| link.text.match? PLAN_PATTERN }
        .max_by { |link| extract_years(link.text) }
    end

    def link_between_headings?
      return unless page

      page.links(skip_files: false, scope: :main, between_headings: [:previous, "État de conformité"])
        .select { |link| link.text.match? PLAN_PATTERN }
        .max_by { |link| extract_years(link.text) }
    end

    def find_text_in_main
      return unless page

      page.text(scope: :main).match(PLAN_PATTERN)&.to_s
    end

    def all_passed? = link_url && valid_year && reachable
    def valid_link? = link_url && reachable

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
        human(:all_passed)
      elsif valid_link?
        human(:invalid_year)
      elsif text
        human(:plan_in_main_text)
      else
        human(:link_not_found)
      end
    end

    alias custom_badge_link link_url

    private

    def analyze!
      link = find_link
      source_text = link&.text || link&.href || find_text_in_main
      return unless source_text

      years = extract_years(source_text)
      {
        years:,
        link_url: link&.href,
        link_text: link&.text,
        link_misplaced: link ? !link_between_headings? : nil,
        valid_year: validate_year(years.last),
        reachable: Browser.reachable?(link&.href),
        text: link ? nil : source_text
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
