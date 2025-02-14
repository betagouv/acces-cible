require "net/http"

class Page < Data.define(:url, :root)
  CACHE_TTL = 10.minutes

  def initialize(url:, root: nil)
    super(url: URI.parse(url), root: URI.parse(root || url))
  end

  def path = url.to_s.delete_prefix(root.to_s)
  def root? = url == root
  def html = Rails.cache.fetch(url, expires_in: CACHE_TTL) { Net::HTTP.get(URI.parse(url)) }
  def dom = Nokogiri::HTML(html)
  def css(selector) = dom.css(selector)
  def title = dom.title&.squish
  def text = dom.text&.squish
  def headings = dom.css("h1,h2,h3,h4,h5,h6").collect(&:text).collect(&:squish)
  def internal_links = links.select { |link| link.href.start_with?(root) }
  def external_links = links - internal_links

  def links
    dom.css("a[href]:not([href^='#']):not([href^=mailto]):not([href^=tel])").collect do |link|
      href = link["href"]
      uri = URI.parse(href)
      if uri.relative?
        relative_path = href.start_with?("/") ? href[1..-1] : href
        uri = URI.parse(root.to_s.chomp("/") + "/" + relative_path)
      end
      uri.fragment = nil
      uri.query = nil
      Link.new(uri, link.text)
    end.compact
  end
end
