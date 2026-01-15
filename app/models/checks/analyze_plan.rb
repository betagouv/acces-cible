module Checks
  class AnalyzePlan < Check
    PRIORITY = 24
    REQUIREMENTS = Check::REQUIREMENTS + [:find_accessibility_page]
    YEAR_REGEX = /\d{4}/
    PLAN_PATTERN = /
      plan\s+
      (?:
        annuel\s+(?:de\s+mise\s+en\s+|d['’])?accessibilit[eé](?:\s+num[eé]rique)?(?:\s+\d{4}(?:\s*[-–]\s*\d{4})?)?|
        annuel\s+\d{4}(?:\s*[-–]\s*\d{4})?|
        (?:\d{4}\s+)?d['’]action(?:s)?(?:\s+\d{4}(?:\s*[-–]\s*\d{4})?)?
      )
    /xi

    store_accessor :data, :link_url, :link_text, :link_misplaced, :years, :reachable, :valid_year, :text

    def find_link
      return unless page

      page.links(skip_files: false, scope: :main)
          .select { |link| link.text.match? PLAN_PATTERN }
          .max_by { |link| extract_valid_years(link.text) }
    end

    def link_between_headings?
      return unless page

      page.links(skip_files: false, scope: :main, between_headings: [:previous, "État de conformité"])
          .select { |link| link.text.match? PLAN_PATTERN }
          .max_by { |link| extract_valid_years(link.text) }
    end

    def find_text_in_main
      return unless page

      page.text(scope: :main)
          .scan(PLAN_PATTERN)
          .flatten
          .compact
          .max_by { |match| extract_valid_years(match) }
    end

    def all_passed?
      link_url && valid_year && reachable
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
        t("checks.analyze_plan.all_passed")
      elsif valid_link?
        years.present? ? t("checks.analyze_plan.invalid_year") : t("checks.analyze_plan.years_not_found")
      elsif text
        t("checks.analyze_plan.plan_in_main_text")
      else
        t("checks.analyze_plan.link_not_found")
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
        valid_year: within_three_years?(years),
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
        years = source.to_s.scan(YEAR_REGEX).map(&:to_i).uniq.sort

        return years if within_three_years?(years)
      end

      result || []
    end

    def within_three_years?(years)
      return false if years.blank?

      years.last.between?(Date.current.year - 1, Date.current.year + 1)
    end
  end
end
