class Crawler
  include Enumerable
  MAX_CRAWLED_PAGES = 5

  class NoMatchError < StandardError
    def initialize(root, crawled)
      # Get parent information from backtrace
      # caller_locations takes 2 arguments: number of skipped frames, number of returned frames
      parent_frame = caller_locations(1, 1).first
      # caller = "method (file.rb:line)"
      caller = "#{parent_frame.label} (#{File.basename(parent_frame.path)}:#{parent_frame.lineno})"
      super("Crawled #{crawled.size} pages starting from #{root.href} but #{caller} found no match.")
    end
  end
  class CrawlLimitReachedError < StandardError
    def initialize(root, crawl_up_to)
      super("Stopping after crawling #{crawl_up_to} pages starting from #{root.href}.")
    end
  end

  def initialize(root, crawl_up_to: nil)
    @root = Link.from(root)
    @crawl_up_to = crawl_up_to || MAX_CRAWLED_PAGES
    @queue = LinkList.new(root)
    @crawled = LinkList.new
  end

  def find(&block)
    found = nil
    detect { |page, queue| found = page if block.call(page, queue) }
    found or raise NoMatchError.new(root, crawled)
  end

  private

  attr_accessor :queue
  attr_reader :root, :crawled, :crawl_up_to

  def each
    while queue.any?
      raise CrawlLimitReachedError.new(root, crawl_up_to) if crawled.size >= crawl_up_to

      next unless page = get_page

      enqueue page.internal_links
      yield page, queue
      break if queue.empty?
    end
  end

  def get_page
    crawled << link = queue.shift
    Rails.logger.info { "#{crawled.size}: Crawling #{link.href}" }
    Page.new(url: link.href, root: root.href)
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
