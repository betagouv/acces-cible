class Page
  HEADINGS = "h1,h2,h3,h4,h5,h6".freeze
  DOCUMENT_EXTENSIONS = /\.(pdf|zip|odt|ods|odp|doc|docx|xls|xlsx|ppt|pptx)$/i
  FILES_EXTENSIONS = /\.(xml|rss|atom|ics|ical|jpg|jpeg|png|gif|mp3|mp4|avi|mov)$/i
  INVISIBLE_ELEMENTS = "script, style, noscript, meta, link, iframe[src], [hidden], [style*='display:none'], [style*='display: none'], [style*='visibility:hidden'], [style*='visibility: hidden']".freeze
  LINKS_SELECTOR = "a[href]:not([href^='#']):not([href^=mailto]):not([href^=tel])".freeze
  SELECTORS = {
    main: "main, [role=main], article, #main, #content, #main-content, .main-content, .content, .site-content"
  }.freeze

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

  attr_reader :url, :root, :status, :html, :actual_url

  def initialize(url:, root: nil, html: nil)
    @url = Link.normalize(url)
    @root = root ? Link.normalize(root) : Link.root_from(url)
    @html = html

    html.present? ? setup_page_data : fetch_page_data
  end

  def root?
    url == root
  end

  def parsed_root
    @parsed_root ||= Link.parse(root)
  end

  def path
    url.to_s.delete_prefix(root.to_s)
  end

  def redirected?
    actual_url.present? && actual_url != url
  end

  def css(selector)
    dom.css(selector)
  end

  def title
    dom.title.to_s.squish
  end

  def text(scope: nil, between_headings: nil)
    source_for(scope:, between_headings:).text&.squish
  end

  def heading_levels
    dom_headings.map { |hx| [hx.name[1].to_i, hx.text.squish] }
  end

  def headings
    dom_headings.collect(&:text).collect(&:squish)
  end

  def internal_links
    links.select { |link| link.href.start_with?(root) }
  end

  def external_links
    links - internal_links
  end

  def inspect
    "#<#{self.class.name} @url=#{url.inspect} @title=#{title}>"
  end

  def success?
    status == Rack::Utils::SYMBOL_TO_STATUS_CODE[:ok]
  end

  def error?
    status > 399
  end

  def dom
    @dom ||= Nokogiri::HTML(html).tap do |document|
      document.css(INVISIBLE_ELEMENTS).each(&:remove)
      document.xpath("//text()[normalize-space(.) != '']").each { |node| node.content = " #{node.content} " }
    end
  rescue Nokogiri::SyntaxError => e
    raise ParseError.new url, e.message
  end

  def links(skip_files: true, scope: nil, between_headings: nil)
    source_for(scope:, between_headings:).css(LINKS_SELECTOR).collect do |link|
      href = link["href"].to_s
      next if href.downcase.match?(/\A(?:javascript:|data:|blob:|void\s*\()/)

      uri = Link.parse(href)
      next if uri.path && File.extname(uri.path).match?(FILES_EXTENSIONS)
      next if skip_files && uri.path && File.extname(uri.path).match?(DOCUMENT_EXTENSIONS)

      href = parsed_root.join(uri) unless uri.absolute?
      text = [link.text, link.at_css("img")&.attribute("alt")&.value].compact.join(" ").squish
      Link.new(href:, text:)
    rescue Link::InvalidUriError
      next
    end.compact
  end

  private

  def setup_page_data
    @actual_url = @url
    @status = 200
    @content_type = "text/html"
  end

  def is_html_page?
    @content_type && @content_type.include?("text/html")
  end

  def fetch_page_data
    @actual_url, @status, @content_type, @html = Browser.get(url.to_s).values_at(:current_url, :status, :content_type, :body)

    raise InvalidTypeError.new(url, @content_type) unless is_html_page?
  end

  def dom_headings
    @dom_headings ||= dom.css(HEADINGS)
  end

  def heading(matcher, scope: nil)
    source_for(scope:).css(HEADINGS).find do |heading|
      if matcher.is_a?(Regexp)
        matcher.match?(heading.text.squish)
      else
        StringComparison.match?(matcher, heading.text.squish, ignore_case: true, fuzzy: 0.85)
      end
    end
  end

  def heading_relative_to(node, direction, headings = dom_headings)
    index = headings.index(node)
    return nil unless index

    case direction
    when :next
      headings[index + 1]
    when :previous
      index > 0 ? headings[index - 1] : nil
    end
  end

  def find_heading_nodes(start_matcher, end_matcher, scope: nil)
    headings = source_for(scope:).css(HEADINGS)

    if start_matcher == :previous
      end_node = heading(end_matcher, scope:)
      start_node = heading_relative_to(end_node, :previous, headings)
    elsif end_matcher == :next
      start_node = heading(start_matcher, scope:)
      end_node = heading_relative_to(start_node, :next, headings)
    else
      start_node = heading(start_matcher, scope:)
      end_node = heading(end_matcher, scope:)
    end

    [start_node, end_node]
  end

  def source_for(scope: nil, between_headings: nil)
    if between_headings
      start_matcher, end_matcher = between_headings
      start_node, end_node = find_heading_nodes(start_matcher, end_matcher, scope:)
      return dom.fragment unless start_node && end_node
      dom_between(start_node, end_node)
    else
      scope ? (css(SELECTORS[scope]).first || dom) : dom
    end
  end

  def dom_between(start_node, end_node)
    # Find all nodes between start_node and end_node
    # (following-siblings only works when nodes are at the same level)
    nodes_between = start_node.xpath("following::*") & end_node.xpath("preceding::*")

    # Remove nodes whose parent is already included (UL>LI,P>EM etc)
    deduped_nodes = nodes_between.reject do |node|
      node.ancestors.any? { |ancestor| nodes_between.include?(ancestor) }
    end

    dom.fragment.tap do |fragment|
      deduped_nodes.each { |node| fragment.add_child(node.dup) }
    end
  end
end
