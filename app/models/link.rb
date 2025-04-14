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

    def normalize(href)
      uri = Addressable::URI.parse(href.dup)
      uri.fragment = nil # Fragments shouldn't change the target document

      return uri if uri.relative?
      return Addressable::URI.join(uri, "/") if uri.path.empty?

      origin = uri.origin
      origin = "#{origin}/" unless origin.end_with?("/") # Ensure the origin ends with a slash for proper joining
      normalized_path = File.expand_path(uri.path, "/")
      normalized_path = normalized_path[1..-1] if normalized_path.start_with?("/")
      query = uri.query.nil? ? "" : "?#{uri.query}"

      Addressable::URI.join(origin, normalized_path) + query
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
