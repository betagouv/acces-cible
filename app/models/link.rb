Link = Data.define(:href, :text) do
  def initialize(href:, text: nil)
    super(href: href.to_s, text: text&.squish || "")
  end

  def self.from(source)
    case source
    when Link then source
    when String, URI then Link.new(href: source)
    else raise ArgumentError.new("#{source.class.name} is not allowed in Link.from")
    end
  end

  def to_str = href
  def ==(other) = href == other
end
