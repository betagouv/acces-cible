# frozen_string_literal: true

Link = Data.define(:href, :text) do
  include Comparable

  class << self
    def from(source)
      case source
      when Link then source
      when String, URI, Addressable::URI then Link.new(href: source)
      else raise ArgumentError.new("#{source.class.name} is not allowed in Link.from")
      end
    end

    def parse(href)
      href = "/" if href == "//" # Addressable considers // to be an absolute url instead of a path
      Addressable::URI.parse(href.to_s.strip)
    rescue Addressable::URI::InvalidURIError
      raise Link::InvalidUriError.new(href)
    end

    def normalize(href)
      uri = parse(href)
      uri.fragment = nil # Fragments shouldn't change the target document
      return uri if uri.relative?

      path = uri.path
      path = path.gsub("//", "/")
      unless path == "/"
        path = File.expand_path(uri.path, "/")
        path = path[1..-1] if path.start_with?("/")
        path += "/" if uri.path.end_with?("/")
      end
      query = uri.query.nil? ? "" : "?#{uri.query}"
      Addressable::URI.join(uri.origin, path, query).display_uri.to_s
    rescue Addressable::URI::InvalidURIError
      raise Link::InvalidUriError.new(href)
    end

    def url_without_scheme_and_www(href)
      return "" unless href

      parsed_url = parse(href)
      hostname = parsed_url.hostname.to_s.gsub(/\Awww\./, "")
      path = parsed_url.path == "/" ? nil : parsed_url.path
      [hostname, path].compact.join(nil)
    rescue Link::InvalidUriError
      ""
    end

    def internal?(href, root)
      url_without_scheme_and_www(href).start_with?(url_without_scheme_and_www(root))
    end

    # Extract the domain and path up to the last slash
    # Eg: https://example.com/folder/page.html -> https://example.com/folder/
    def root_from(href)
      uri = parse(href)
      uri.query = nil
      return normalize(href) unless uri.path

      uri.path = uri.path[0..uri.path.rindex("/")] || "/"
      normalize(uri)
    end
  end

  delegate :normalize, to: :class
  delegate :hash, to: :href

  def initialize(href:, text: "")
    super(href: normalize(href).to_s, text: text&.squish || "")
  end

  def to_str
    href
  end

  def ==(other)
    href == other.to_str
  end

  def <=>(other)
    other.is_a?(Link) ? href <=> other.href : nil
  end

  def eql?(other)
    other.is_a?(Link) && href == other.href
  end
end
