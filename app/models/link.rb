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
      uri.fragment = nil
      return uri.to_s if uri.relative?

      uri.path = uri.path.gsub(%r{/+}, "/")
      uri.normalize.display_uri.to_s
    end

    def safe_external_url(href)
      return if href.blank?

      uri = parse(href)
      uri.to_s if uri.host.present? && uri.scheme&.in?(%w[http https])
    rescue Addressable::URI::InvalidURIError
      nil
    end

    def url_without_scheme_and_www(href)
      return "" unless href

      uri = parse(href)
      hostname = uri.hostname.to_s.delete_prefix("www.")
      path = uri.path unless uri.path == "/"
      [hostname, path].compact.join
    rescue Addressable::URI::InvalidURIError
      ""
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
