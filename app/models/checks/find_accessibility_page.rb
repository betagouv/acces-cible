module Checks
  class FindAccessibilityPage < Check
    SLOW = true
    PRIORITY = 20
    DECLARATION = /\A(D[ée]claration d('|’))?accessibilit[ée]?/i
    DECLARATION_URL = /"(declaration-)?accessibilit[e|y]"/i
    REQUIRED_DECLARATION_HEADINGS = 3
    ARTICLE = /(?:art(?:icle)?\.? 47|article 47) (?:de la )?loi (?:n[°˚]|num(?:éro)?\.?) ?2005-102 du 11 (?:février|fevrier) 2005/i

    store_accessor :data, :url, :title

    def found? = url.present?

    def custom_badge_text = found? ? human(:link_to_page) : human(:not_found)
    def custom_badge_status = found? ? :success : :error
    def custom_badge_link = url

    private

    def analyze!
      return unless (page = find_page)

      { url: page.url, title: page.title }
    end

    def find_page
      crawler.find do |current_page, queue|
        if mentions_article?(current_page) && required_headings_present?(current_page)
          true
        else
          filter_queue(queue)
          false
        end
      end
    end

    def mentions_article?(current_page) = current_page.text.match?(ARTICLE)

    def required_headings_present?(current_page)
      matching_headings = current_page.headings.select do |heading|
        AccessibilityPageHeading.expected_headings.each do |required_heading|
          fuzzy_match?(heading, required_heading)
        end
      end
      matching_headings.size >= REQUIRED_DECLARATION_HEADINGS
    end

    def fuzzy_match?(a, b) = StringComparison.similar?(a, b, ignore_case: true, fuzzy: 0.6)

    def filter_queue(queue)
      queue.filter! do |link|
        link.href.match?(DECLARATION_URL) ||
        link.text.match?(DECLARATION) ||
        link.text.match?(Checks::AccessibilityMention::MENTION_REGEX)
      end
    end
  end
end
