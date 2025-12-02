module Checks
  class FindAccessibilityPage < Check
    PRIORITY = 20

    store_accessor :data, :url

    def found?
      url.present?
    end

    def custom_badge_text
      found? ? human(:link_to_page) : human(:not_found)
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
