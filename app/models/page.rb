class Page
  CACHE_TTL = 10.minutes
  HEADINGS = "h1,h2,h3,h4,h5,h6".freeze
  SKIPPED_EXTENSIONS = /\.(xml|rss|atom|pdf|zip|doc|docx|xls|xlsx|ppt|pptx|jpg|jpeg|png|gif|mp3|mp4|avi|mov)$/i
  INVISIBLE_ELEMENTS = "script, style, noscript, meta, link, iframe[src], [hidden], [style*='display:none'], [style*='display: none'], [style*='visibility:hidden'], [style*='visibility: hidden']".freeze

  class InvalidTypeError < StandardError
    def initialize(url, content_type)
      super("Not an HTML page: #{url} (Content-Type: #{content_type})")
    end
  end
  class ParseError < StandardError
    def initialize(url, message)
      super("Failed to parse HTML from #{url}: #{message}")
    end
  end

  attr_reader :url, :root, :status, :html, :headers, :actual_url

  def initialize(url:, root: nil, html: nil)
    @url = Link.normalize(url)
    @root = Link.normalize(root || url)
    @status = 200
    @html = html || fetch&.last
  end

  def root? = url == root
  def path = url.to_s.delete_prefix(root.to_s)
  def redirected? = actual_url.present? && actual_url != url
  def css(selector) = dom.css(selector)
  def title = dom.title&.squish
  def text = dom.text&.squish
  def heading_levels = dom.css(HEADINGS).map { |hx| [hx.name[1].to_i, hx.text.squish] }
  def headings = dom.css(HEADINGS).collect(&:text).collect(&:squish)
  def internal_links = links.select { |link| link.href.start_with?(root) }
  def external_links = links - internal_links
  def inspect =  "#<#{self.class.name} @url=#{url.inspect} @title=#{title}>"
  def success? = status == 200
  def error? = status > 399
  def refresh = fetch(clear: true)

  def dom
    Nokogiri::HTML(html).tap do |document|
      document.css(INVISIBLE_ELEMENTS).each(&:remove)
    end
  rescue Nokogiri::SyntaxError => e
    raise ParseError.new url, e.message
  end

  def links
    dom.css("a[href]:not([href^='#']):not([href^=mailto]):not([href^=tel])").collect do |link|
      href = link["href"]
      uri = Link.parse(href)
      next if uri.path && File.extname(uri.path).match?(SKIPPED_EXTENSIONS)

      href = Link.normalize("#{root}#{href}") unless uri.hostname
      text = [link.text, link.at_css("img")&.attribute("alt")&.value].compact.join(" ").squish
      Link.new(href:, text:)
    end.uniq.compact
  end

  private

  def fetch(clear: false)
    Rails.cache.clear(url) if clear
    Rails.cache.fetch(url, expires_in: CACHE_TTL) do
      @actual_url, @status, @headers, @html = Browser.get(url.to_s).values_at(:current_url, :status, :headers, :body)
      content_type = headers["Content-Type"]
      if content_type && !content_type.include?("text/html")
        raise InvalidTypeError.new url, content_type
      end
      [@actual_url, @status, @headers, @html]
    rescue Ferrum::Error => e
      Rails.logger.error { "Browser error fetching #{url}: #{e.message}" }
      raise e
    end
  end
end
