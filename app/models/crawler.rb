class Crawler
  include Enumerable
  MAX_CRAWLED_PAGES = 100

  class NoMatchError < StandardError; end
  class CrawlLimitReachedError < StandardError; end

  def initialize(root, crawl_up_to: nil)
    @root = Link.new(root)
    @crawl_up_to = crawl_up_to || MAX_CRAWLED_PAGES
    @queue = LinkList.new(root)
    @crawled = LinkList.new
  end

  def find(&block)
    detect(&block) or raise NoMatchError
  end

  private

  attr_accessor :queue
  attr_reader :root, :crawled, :crawl_up_to

  def each
    return to_enum(:each) unless block_given?

    while queue.any? && crawled.size < crawl_up_to
      page = get_page
      enqueue page.internal_links

      yield page, queue

      break if queue.empty? || queue == crawled
    end
  end

  def get_page
    crawled << link = queue.shift
    Rails.logger.info { "#{crawled.size}: Crawling #{link.href}" }
    Page.new(link.href, root)
  end

  def enqueue(links)
    queue.add(*links.reject { |link| crawled.include?(link) })
  end
end
