module Checks
  class Reachable < Check
    PRIORITY = 0 # This needs to run before all other checks
    REQUIREMENTS = []

    store_accessor :data, :original_url, :redirect_url

    def redirected?
      return if audit.home_page_url.blank?

      normalize(audit.home_page_url) != normalize(audit.url)
    end

    def custom_badge_text
      t(redirected? ? "redirected" : "reachable", scope: "checks.reachable")
    end

    def custom_badge_status
      redirected? ? :info : :success
    end

    private

    def analyze!
      return unless root_page.success?

      site.update(name: root_page.title) if site && site.name.blank?

      if redirected?
        { original_url: audit.url, redirect_url: audit.home_page_url }
      else
        {}
      end
    end

    def normalize(url)
      parsed = Link.parse(url.downcase)
      host = parsed.host.start_with?("www.") ? parsed.host[4..-1] : parsed.host
      {
        host: host,
        path: parsed.path,
        query: parsed.query,
        fragment: parsed.fragment
      }
    end
  end
end
