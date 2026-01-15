class Crawler
  MAX_CRAWLED_PAGES = 5

  def initialize(root, crawl_up_to: nil, root_page_html: nil, queue: nil)
    @root = Link.from(Link.root_from(root))
    @crawl_up_to = crawl_up_to || MAX_CRAWLED_PAGES
    @root_page_html = root_page_html
    @queue = queue || LinkList.new(root)
    @crawled = LinkList.new
  end

  def find_page(&block)
    each_page { |page| return page if block.call(page) }
  end

  private

  attr_accessor :queue
  attr_reader :root, :crawled, :crawl_up_to, :root_page_html

  def each_page
    while queue.any?
      return if crawled.size >= crawl_up_to
      page = get_page

      next unless page

      yield page
      break if queue.empty?
    end
  end

  def create_page!(link)
    html = if link.href == root.href && root_page_html.present?
      root_page_html
    else
      nil
    end

    Page.new(url: link.href, root: root.href, html: html)
  end

  def get_page
    link = queue.shift
    return nil unless link

    crawled << link
    Rails.logger.info { "#{crawled.size}: Crawling #{link.href}" }

    create_page!(link)
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
end
