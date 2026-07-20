class FindAccessibilityPageService
  DECLARATION_TERMS = %w[rgaa conform declaration accessibilit].freeze
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
        audit.site.url,
        audit.home_page_url
      ].compact.map { |url| Link.url_without_scheme_and_www(url) }.uniq

      children_links = page.links.reject do |link|
        excluded_targets.include?(Link.url_without_scheme_and_www(link.href))
      end

      children_links = links_by_priority(children_links).first(Crawler::MAX_CRAWLED_PAGES)

      queue.concat(children_links.map(&:href))
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
      root = Link.root_from(url)
      links = if starting_html.present?
        Page.new(url:, root:, html: starting_html).links
      else
        []
      end

      links_by_priority(links).map(&:href)
    end

    def links_by_priority(links)
      (
        links.select { |link| link.text.match?(Checks::AccessibilityMention::MENTION_REGEX) } +
          links.select { |link| declaration_term_count(link) }
               .sort_by { |link| -declaration_term_count(link) }
      ).uniq(&:href)
    end

    def declaration_term_count(link)
      normalized_text = I18n.transliterate(link.text).downcase
      normalized_href = I18n.transliterate(link.href).downcase

      DECLARATION_TERMS.count { |term| normalized_href.include?(term) || normalized_text&.include?(term) }.nonzero?
    end
  end
end
