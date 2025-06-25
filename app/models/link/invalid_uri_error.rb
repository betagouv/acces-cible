class Link
  class InvalidUriError < StandardError
    def initialize(href)
      super("Addressable::URI cannot parse '#{href}'")
    end
  end
end
