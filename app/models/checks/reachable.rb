module Checks
  class Reachable < Check
    class UnreachableSiteError < StandardError
      def initialize(url, status)
        super("Server response #{status} when trying to get #{url}")
      end
    end

    PRIORITY = 0 # This needs to run before all other checks
    REQUIREMENTS = nil

    store_accessor :data, :original_url, :redirect_url

    def redirected? = original_url && redirect_url && normalize(original_url) != normalize(redirect_url)

    private

    def custom_badge_text = redirected? ? human(:redirected) : human(:reachable)
    def custom_badge_status = redirected? ? :info : :success

    def analyze!
      raise UnreachableSiteError.new(audit.url, root_page.status) unless root_page.success?

      site.update(name: root_page.title) if site && site.name.blank?
      if root_page.redirected?
        audit.update(url: root_page.actual_url)
        { original_url: root_page.url, redirect_url: root_page.actual_url }
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
