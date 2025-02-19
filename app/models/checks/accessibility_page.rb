module Checks
  class AccessibilityPage < Check
    DECLARATION = /Déclaration d(’|')accessibilité( RGAA)?/i
    ARTICLE = /(?:art(?:icle)?\.? 47|article 47) (?:de la )?loi (?:n[°˚]|num(?:éro)?\.?) ?2005-102 du 11 (?:février|fevrier) 2005/i

    store_accessor :data, :url, :title

    private

    def found? = url.present?
    def custom_badge_text = found? ? human(:link_to, name: site&.name) : human(:not_found)
    def custom_badge_status = found? ? :success : :error
    def custom_badge_link = url

    def analyze!
      return {} unless page = find_page

      {
        url: page.url,
        title: page.title
      }
    end

    def find_page
      crawl.find do |page, queue|
        return page if accessibility_page?(page)

        queue.sort_by! { |link_a, link_b| likelihood_of(link_a) <=> likelihood_of(link_b) }
      end
    end

    def accessibility_page?(page)
      page.title.match?(DECLARATION) || page.headings.any?(DECLARATION) || page.text.match?(ARTICLE)
    end

    def likelihood_of(link)
      return 0 unless link.is_a?(Link)

      [
        link.text.match?(DECLARATION),
        link.href.match?("(declaration-)?accessibilite"),
        link.text.match?(AccessibilityMention::MENTION_REGEX),
      ].count(&:itself).then { |n| n.zero? ? -1 : n - 1 } # Subtract 1 so the returned value can be compared using <=>
    end
  end
end
