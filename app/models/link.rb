# frozen_string_literal: true

class Link
  attr_reader :href, :text

  def initialize(href:, text: "")
    @href = Link.normalize(href.to_s)
    @text = text&.squish || ""
  end

  class << self
    def parse(href)
      Addressable::URI.parse(href.to_s.strip)
    end

    def normalize(href)
      uri = parse(href)
      uri.fragment = route_fragment(uri)
      return uri.to_s if uri.relative?

      uri.path = uri.path.squeeze("/")
      uri.normalize.display_uri.to_s
    end

    def route_fragment(href)
      fragment = parse(href).fragment
      fragment if fragment&.start_with?("/")
    end

    def safe_external_url(href)
      return if href.blank?

      uri = parse(href)
      uri.to_s if uri.host.present? && uri.scheme&.in?(%w[http https])
    rescue Addressable::URI::InvalidURIError
      nil
    end

    def url_without_scheme(href)
      return "" unless href

      uri = parse(href)
      path = uri.path unless uri.path == "/"
      [uri.hostname, path].compact.join
    rescue Addressable::URI::InvalidURIError
      ""
    end

    def url_without_scheme_and_www(href)
      url_without_scheme(href).delete_prefix("www.")
    end

    def internal?(href, root)
      url_without_scheme_and_www(href).start_with?(url_without_scheme_and_www(root))
    end

    # Returns the directory portion of a URL
    # e.g. https://example.com/folder/page.html → https://example.com/folder/
    def root_from(href)
      uri = parse(href)
      uri.query = nil
      uri.path = uri.path.sub(%r{[^/]+\z}, "")
      normalize(uri)
    end
  end
end
