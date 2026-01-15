module AccessibilityDocumentAnalyzer
  extend ActiveSupport::Concern

  REQUIREMENTS = Check::REQUIREMENTS + [:find_accessibility_page]
  YEAR_PATTERN = /20\d{2}/

  included do
    def find_link
      return unless page

      page.links(skip_files: false, scope: :main)
          .select { |link| link.text.match? self.class::PATTERN }
          .max_by { |link| extract_valid_years(link.text) }
    end

    def link_between_headings?
      return unless page

      page.links(skip_files: false, scope: :main, between_headings: [:previous, "État de conformité"])
          .select { |link| link.text.match? self.class::PATTERN }
          .max_by { |link| extract_valid_years(link.text) }
    end

    def find_text_in_main
      return unless page

      page.text(scope: :main)
          .scan(self.class::PATTERN)
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
      elsif link_url.present? || text.present?
        :warning
      else
        :error
      end
    end

    def custom_badge_text
      if all_passed?
        t("checks.#{model_name.element}.all_passed")
      elsif years.present? && !valid_years
        t("checks.#{model_name.element}.invalid_years")
      elsif years.blank? && (link_url.present? || text.present?)
        t("checks.#{model_name.element}.years_not_found")
      elsif text.present?
        t("checks.#{model_name.element}.in_main_text")
      else
        t("checks.#{model_name.element}.link_not_found")
      end
    end

    private

    def page
      @page ||= audit.page(:accessibility)
    end

    def extract_valid_years(*sources)
      sources
        .compact
        .map { |source| source.to_s.scan(YEAR_PATTERN).map(&:to_i).uniq.sort }
        .find(&:any?) || []
    end
  end
end
