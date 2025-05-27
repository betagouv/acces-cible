Link = Data.define(:href, :text) do
  include Comparable

  SLASH = "/".freeze
  EMPTY_STRING = "".freeze

  class InvalidURIError < StandardError
    def initialize(href)
      super("Addressable::URI cannot parse '#{href}'")
    end
  end

  class << self
    def from(source)
      case source
      when Link then source
      when String, URI, Addressable::URI then Link.new(href: source)
      else raise ArgumentError.new("#{source.class.name} is not allowed in Link.from")
      end
    end

    def parse(href)
      Addressable::URI.parse(href.to_s.strip)
    rescue Addressable::InvalidURIError
      raise InvalidURIError.new(href)
    end

    def normalize(href)
      uri = parse(href)
      uri.fragment = nil # Fragments shouldn't change the target document
      return uri if uri.relative?

      path = uri.path
      unless path == SLASH
        path = File.expand_path(uri.path, SLASH)
        path = path[1..-1] if path.start_with?(SLASH)
        path += SLASH if uri.path.end_with?(SLASH) || File.extname(path).empty?
      end
      query = uri.query.nil? ? EMPTY_STRING : "?#{uri.query}"
      Addressable::URI.join(uri.origin, path, query).display_uri.to_s
    end
  end

  delegate :normalize, to: :class
  delegate :hash, to: :href

  def initialize(href:, text: "")
    super(href: normalize(href).to_s, text: text&.squish || "")
  end

  def to_str = href
  def ==(other) = href == other.to_str
  def <=>(other) = other.is_a?(Link) ? href <=> other.href : nil
  def eql?(other) = other.is_a?(Link) && href == other.href
end
