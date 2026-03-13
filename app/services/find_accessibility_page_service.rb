class FindAccessibilityPageService
  DECLARATION = /\A(D[ée]claration d('|'))?accessibilit[ée]?/i
  DECLARATION_URL = /(declaration-)?d?accessibilit[e|y]|rgaa/i
  REQUIRED_DECLARATION_HEADINGS = 2

  class << self
    def call(audit)
      queue = prioritize_queue!(url: audit.home_page_url, starting_html: audit.home_page_html)
      crawler = Crawler.new(audit.home_page_url, root_page_html: audit.home_page_html, queue: queue)
      page = find_page(crawler, queue, audit)

      Rails.logger.silence do
        audit.update_accessibility_page!(page.url, page.html) unless page.nil?
      end
    end

    private

    def find_page(crawler, queue, audit)
      crawler.find_page do |current_page|
        if required_headings_present?(current_page)
          true
        else
          enqueue_children(current_page, queue, audit)
          false
        end
      end
    end

    def enqueue_children(page, queue, audit)
      excluded_targets = [
        page.url,
        audit.url,
        audit.home_page_url
      ].compact.map { |url| Link.url_without_scheme_and_www(url) }.uniq

      children_links = page.internal_links.reject do |link|
        excluded_targets.include?(Link.url_without_scheme_and_www(link.href))
      end

      children_links = links_by_priority(children_links).first(Crawler::MAX_CRAWLED_PAGES)

      queue.add(*children_links)
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
      StringComparison.match?(a, b, ignore_case: true, fuzzy: 0.8)
    end

    def prioritize_queue!(url:, starting_html:)
      root_link = Link.from(Link.root_from(url))
      links = if starting_html.present?
        Page.new(url:, root: root_link.href, html: starting_html).internal_links
      else
        []
      end

      LinkList.new(links_by_priority(links))
    end

    def links_by_priority(links)
      (
        links.select { |link| link.text.match?(Checks::AccessibilityMention::MENTION_REGEX) } +
          links.select { |link| link.text.match?(DECLARATION) } +
          links.select { |link| link.href.match?(DECLARATION_URL) }
      ).uniq
    end
  end
end
