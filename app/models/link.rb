Link = Data.define(:href, :text) do
  def initialize(href:, text:)
    super(href: href.to_s, text: text&.squish || "")
  end

  def to_str = href
  def ==(other) = href == other.href
end
