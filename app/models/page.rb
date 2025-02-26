require "net/http"

class Page < Data.define(:url, :root)
  CACHE_TTL = 10.minutes
  SKIPPED_EXTENSIONS = /\.(xml|rss|atom|pdf|zip|doc|docx|xls|xlsx|ppt|pptx|jpg|jpeg|png|gif|mp3|mp4|avi|mov)$/i

  class InvalidTypeError < StandardError
    def initialize(url, content_type)
      super("Not an HTML page: #{url} (Content-Type: #{content_type})")
    end
  end
  class ParseError < StandardError
    def initialize(url, message)
      super("Nokogiri failed to parse HTML from #{url}: #{message}")
    end
  end

  def initialize(url:, root: nil, html: nil)
    # Allow setting HTML directly to simplify testing and avoid network calls.
    # The `html` method overwrites the instance variable, so we need to set it explicitly
    @html = html
    super(url: URI.parse(url), root: URI.parse(root || url))
  end

  def path = url.to_s.delete_prefix(root.to_s)
  def root? = url == root
  def css(selector) = dom.css(selector)
  def title = dom.title&.squish
  def text = dom.text&.squish
  def headings = dom.css("h1,h2,h3,h4,h5,h6").collect(&:text).collect(&:squish)
  def internal_links = links.select { |link| link.href.start_with?(root) }
  def external_links = links - internal_links
  def inspect =  "#<#{self.class.name} @url=#{url.inspect} @title=#{title}>"

 def html
   @html || Rails.cache.fetch(url, expires_in: CACHE_TTL) do
     response = Net::HTTP.get_response(url)
     if response["Content-Type"]&.include?("text/html")
       response.body
     else
       raise InvalidTypeError.new url, response["Content-Type"]
     end
   end
 end

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
      Link.new(uri, link.text)
    end.compact
  end
end
