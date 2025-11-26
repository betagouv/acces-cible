module Checks
  class FindAccessibilityPage < Check
    PRIORITY = 20
    DECLARATION = /\A(D[ée]claration d('|’))?accessibilit[ée]?/i
    DECLARATION_URL = /(declaration-)?d?accessibilit[e|y]|rgaa/i
    REQUIRED_DECLARATION_HEADINGS = 3
    MAX_CRAWLED_PAGES = 10

    store_accessor :data, :url, :title

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
      return unless (page = find_page)

      audit.update(accessibility_page_html: page.html)

      { url: page.url, title: page.title }
    end

    def find_page
      crawler(crawl_up_to: MAX_CRAWLED_PAGES).find do |current_page, queue|
        if required_headings_present?(current_page)
          true
        else
          prioritize(queue)
          false
        end
      end
    end

    def required_headings_present?(current_page)
      matching_headings = current_page.headings.select do |heading|
        AccessibilityPageHeading.expected_headings.any? do |required_heading|
          fuzzy_match?(heading, required_heading)
        end
      end
      matching_headings.size >= REQUIRED_DECLARATION_HEADINGS
    end

    def fuzzy_match?(a, b)
      StringComparison.match?(a, b, ignore_case: true, fuzzy: 0.6)
    end

    def prioritize(queue)
      queue.filter! do |link|
        link.text.match?(Checks::AccessibilityMention::MENTION_REGEX) ||
          link.text.match?(DECLARATION) ||
          link.href.match?(DECLARATION_URL)
      end
    end
  end
end
