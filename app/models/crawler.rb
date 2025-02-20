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
    found = nil
    detect { |page, queue| found = page if block.call(page, queue) }
    found or raise NoMatchError
  end

  private

  attr_accessor :queue
  attr_reader :root, :crawled, :crawl_up_to

  def each
    while queue.any? && crawled.size < crawl_up_to
      page = get_page
      next unless page

      enqueue page.internal_links
      yield page, queue
      break if queue.empty?
    end
  end

  def get_page
    crawled << link = queue.shift
    Rails.logger.info { "#{crawled.size}: Crawling #{link.href}" }
    Page.new(link.href, root)
  rescue StandardError => e
    case e
    when Page::InvalidTypeError
      Rails.logger.info { "Skipping non-HTML page #{link.href}" }
    when SocketError, Timeout::Error, Errno::ECONNREFUSED
      Rails.logger.warn { "Network error crawling #{link.href}: #{e.message}" }
    else
      Rails.logger.error { "Unexpected error crawling #{link.href}: #{e.message}" }
    end
    nil
  end

  def enqueue(links)
    queue.add(*links.reject { |link| crawled.include?(link) })
  end
end
