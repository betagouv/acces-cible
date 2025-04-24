Link = Data.define(:href, :text) do
  include Comparable

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
      Addressable::URI.parse(href)
    rescue Addressable::InvalidURIError
      raise InvalidURIError.new(href)
    end

    def normalize(href)
      uri = parse(href)
      uri.fragment = nil # Fragments shouldn't change the target document
      return uri if uri.relative?

      origin = uri.origin.end_with?("/") ? uri.origin : "#{uri.origin}/"
      return Addressable::IDNA.to_unicode(origin) unless uri.path.present? || uri.query

      normalized_path = File.expand_path(uri.path, "/")
      normalized_path = normalized_path[1..-1] if normalized_path.start_with?("/")
      normalized_path += "/" if uri.path.end_with?("/") || File.extname(normalized_path).empty?
      query = uri.query.nil? ? "" : "?#{uri.query}"

      Addressable::IDNA.to_unicode Addressable::URI.join(uri.origin, normalized_path, query)
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
