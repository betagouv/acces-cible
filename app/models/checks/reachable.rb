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

    private

    def redirected? = redirect_url.present?
    def custom_badge_text = redirected? ? human(:redirected) : human(:reachable)
    def custom_badge_status = redirected? ? :info : :success

    def analyze!
      raise UnreachableSiteError.new(audit.url, root_page.status) unless root_page.success?

      if root_page.redirected?
        audit.update(url: root_page.actual_url)
        { original_url: root_page.url, redirect_url: root_page.actual_url }
      else
        {}
      end
    end
  end
end
