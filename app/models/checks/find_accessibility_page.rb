module Checks
  class FindAccessibilityPage < Check
    PRIORITY = 20
    DECLARATION = /\AD[ée]claration d('|’)accessibilit[ée]?/i
    ARTICLE = /(?:art(?:icle)?\.? 47|article 47) (?:de la )?loi (?:n[°˚]|num(?:éro)?\.?) ?2005-102 du 11 (?:février|fevrier) 2005/i

    store_accessor :data, :url, :title

    def found? = url.present?

    private

    def custom_badge_text = found? ? human(:link_to, name: site&.name) : human(:not_found)
    def custom_badge_status = found? ? :success : :error
    def custom_badge_link = url

    def analyze!
      return {} unless (page = find_page)

      { url: page.url, title: page.title }
    end

    def find_page
      crawler.find do |current_page, queue|
        if accessibility_page?(current_page)
          true
        else
          sort_queue_by_likelihood(queue)
          false
        end
      end
    end

    def accessibility_page?(current_page)
      current_page.title.match?(DECLARATION) ||
        current_page.headings.any?(DECLARATION) ||
        current_page.text.match?(ARTICLE)
    end

    def sort_queue_by_likelihood(queue)
      queue.sort_by! { |link| likelihood_of(link) }
    end

    # Most relevant links need to have a negative score to come first in the queue
    def likelihood_of(link)
      return unless link.is_a?(Link)

      [
        link.text.match?(DECLARATION),
        link.href.match?("(declaration-)?accessibilite"),
        link.text.match?(Checks::AccessibilityMention::MENTION_REGEX)
      ].count(&:itself).then { |n| n.zero? ? 1 : -n + 1 }
    end
  end
end
