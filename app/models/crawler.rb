class Crawler
  MAX_CRAWLED_PAGES = 5

  def initialize(root, crawl_up_to: nil, root_page_html: nil, queue: nil)
    @root = Link.root_from(root)
    @crawl_up_to = crawl_up_to || MAX_CRAWLED_PAGES
    @root_page_html = root_page_html
    @queue = queue || [Link.normalize(root)]
    @crawled = []
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
      yield page if page
    end
  end

  def create_page!(href)
    html = href == root && root_page_html.present? ? root_page_html : nil
    Page.new(url: href, root: root, html: html)
  end

  def get_page
    href = queue.shift
    return if crawled.include?(href)

    crawled << href
    create_page!(href)
  end
end
