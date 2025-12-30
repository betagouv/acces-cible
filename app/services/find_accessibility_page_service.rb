class FindAccessibilityPageService
  DECLARATION = /\A(D[ée]claration d('|'))?accessibilit[ée]?/i
  DECLARATION_URL = /(declaration-)?d?accessibilit[e|y]|rgaa/i
  REQUIRED_DECLARATION_HEADINGS = 2
  MAX_CRAWLED_PAGES = 5

  class << self
    def call(audit)
      find_page(url: audit.home_page_url, starting_html: audit.home_page_html).then do |page|
        Rails.logger.silence do
          audit.update_accessibility_page!(page.url, page.html) unless page.nil?
        end
      end
    end

    private

    def find_page(url:, starting_html:)
      crawler = Crawler.new(url, crawl_up_to: MAX_CRAWLED_PAGES, root_page_html: starting_html)

      crawler.find do |current_page, queue|
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
        Checks::AccessibilityPageHeading.expected_headings.any? do |required_heading|
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
