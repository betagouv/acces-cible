module Checks
  class FindAccessibilityPage < Check
    PRIORITY = 20

    store_accessor :data, :url

    def found?
      url.present?
    end

    def custom_badge_text
      t(found? ? "link_to_page" : "not_found", scope: "checks.find_accessibility_page")
    end

    def custom_badge_status
      found? ? :success : :error
    end

    def custom_badge_link
      url
    end

    private

    def analyze!
      { url: audit.accessibility_page_url }
    end
  end
end
