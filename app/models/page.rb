class Page
  CACHE_TTL = 10.minutes
  SKIPPED_EXTENSIONS = /\.(xml|rss|atom|pdf|zip|doc|docx|xls|xlsx|ppt|pptx|jpg|jpeg|png|gif|mp3|mp4|avi|mov)$/i

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
    @url = URI.parse(url)
    @root = URI.parse(root || url)
    @status = 200
    @html = html || fetch&.last
  end

  def path = url.to_s.delete_prefix(root.to_s)
  def root? = url == root
  def redirected? = actual_url.present? && actual_url != url
  def css(selector) = dom.css(selector)
  def title = dom.title&.squish
  def text = dom.text&.squish
  def headings = dom.css("h1,h2,h3,h4,h5,h6").collect(&:text).collect(&:squish)
  def internal_links = links.select { |link| link.href.start_with?(root) }
  def external_links = links - internal_links
  def inspect =  "#<#{self.class.name} @url=#{url.inspect} @title=#{title}>"
  def success? = status == 200
  def error? = status > 399
  def refresh = fetch(clear: true)

  def dom
    Nokogiri::HTML(html)
  rescue Nokogiri::SyntaxError => e
    raise ParseError.new url, e.message
  end

  def links
    dom.css("a[href]:not([href^='#']):not([href^=mailto]):not([href^=tel])").collect do |link|
      href = link["href"]
      uri = URI.parse(href)
      next if uri.path && File.extname(uri.path).match?(SKIPPED_EXTENSIONS)

      if uri.relative?
        relative_path = href.start_with?("/") ? href[1..-1] : href
        uri = URI.parse(root.to_s.chomp("/") + "/" + relative_path)
      end
      text = [link.text, link.at_css("img")&.attribute("alt")&.value].compact.join(" ").squish
      Link.new(uri, text)
    end.compact
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
