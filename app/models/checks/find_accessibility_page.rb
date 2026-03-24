module Checks
  class FindAccessibilityPage < Check
    PRIORITY = 20

    store_accessor :data, :url, :internal

    def found?
      url.present?
    end

    def external?
      internal == false
    end

    def custom_badge_text
      t(found? ? "link_to_page" : "not_found", scope: "checks.find_accessibility_page")
    end

    def custom_badge_status
      return :error unless found?
      return :warning if external?

      :success
    end

    def custom_badge_link
      url
    end

    private

    def analyze!
      internal = Link.internal?(audit.accessibility_page_url, audit.home_page_url)

      { url: audit.accessibility_page_url, internal: } unless audit.accessibility_page_url.blank?
    end
  end
end
