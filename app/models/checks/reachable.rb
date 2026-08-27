module Checks
  class Reachable < Check
    PRIORITY = 0 # This needs to run before all other checks
    REQUIREMENTS = []

    store_accessor :data, :original_url, :redirect_url

    def redirected?
      return if audit.home_page_url.blank?

      normalized_audit_url = Link.url_without_scheme_and_www(audit.home_page_url)

      normalized_audit_url != audit.site.normalized_url
    end

    def custom_badge_text
      return t("checks.reachable.redirected") if redirected?

      found ? t("checks.reachable.reachable") : t("checks.reachable.not_found")
    end

    def custom_badge_status
      return :info if redirected?

      found ? :success : :error
    end

    private

    def analyze!
      return unless home_page.success?

      if redirected?
        { original_url: site.url, redirect_url: audit.home_page_url }
      else
        {}
      end
    end

    def compute_found
      !data.nil?
    end

    def compute_conform
      compute_found
    end
  end
end
