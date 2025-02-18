Link = Data.define(:href, :text) do
  def initialize(href:, text: nil)
    super(href: href.to_s, text: text&.squish || "")
  end

  def self.from(source)
    case source
    when Link then source
    when String then Link.new(href: source)
    else raise ArgumentError
    end
  end

  def to_str = href
  def ==(other) = href == other
end
