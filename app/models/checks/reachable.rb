module Checks
  class Reachable < Check
    PRIORITY = 0 # This needs to run before all other checks
    REQUIREMENTS = []

    store_accessor :data, :original_url, :redirect_url

    def redirected?
      return if audit.home_page_url.blank?

      normalized_audit_url = Link.url_without_scheme_and_www(audit.home_page_url)

      normalized_audit_url != site.normalized_url
    end

    def custom_badge_text
      if redirected?
        t("checks.reachable.redirected")
      else
        t("checks.reachable.reachable")
      end
    end

    def custom_badge_status
      redirected? ? :info : :success
    end

    private

    def analyze!
      return unless root_page.success?

      site.update(name: root_page.title) if site && site.name.blank?

      if redirected?
        { original_url: site.url, redirect_url: audit.home_page_url }
      else
        {}
      end
    end
  end
end
