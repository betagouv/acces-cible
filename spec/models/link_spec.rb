require "rails_helper"

RSpec.describe Link do
  describe ".normalize" do
    it "removes fragments from URLs" do
      normalized = described_class.normalize("http://example.com/page#section")
      expect(normalized.to_s).to eq("http://example.com/page")
    end

    it "preserves query parameters" do
      normalized = described_class.normalize("http://example.com/page?param=value")
      expect(normalized).to eq("http://example.com/page?param=value")
    end

    it "normalizes paths with doubled slashes" do
      normalized = described_class.normalize("http://example.com/folder//")
      expect(normalized).to eq("http://example.com/folder/")
    end

    it "normalizes paths with parent directory references" do
      normalized = described_class.normalize("http://example.com/folder/../page.html")
      expect(normalized).to eq("http://example.com/page.html")
    end

    it "normalizes paths with current directory references" do
      normalized = described_class.normalize("http://example.com/folder/./page.html")
      expect(normalized).to eq("http://example.com/folder/page.html")
    end

    it "normalizes paths with multiple parent directory references" do
      normalized = described_class.normalize("http://example.com/a/b/c/../../page.html")
      expect(normalized).to eq("http://example.com/a/page.html")
    end

    it "normalizes complex paths with mixed parent and current directory references" do
      normalized = described_class.normalize("http://example.com/a/./b/../c/./d/../page.html")
      expect(normalized).to eq("http://example.com/a/c/page.html")
    end

    it "handles non-standard ports" do
      normalized = described_class.normalize("http://example.com:8080/page.html")
      expect(normalized).to eq("http://example.com:8080/page.html")
    end

    it "doesn't include standard ports in the normalized URL" do
      normalized = described_class.normalize("http://example.com:80/page.html")
      expect(normalized).to eq("http://example.com/page.html")
    end

    it "handles URLs with no path" do
      normalized = described_class.normalize("http://example.com")
      expect(normalized).to eq("http://example.com/")
    end

    it "handles accented URLs" do
      normalized = described_class.normalize("http://www.lucé.fr/./..///")
      expect(normalized).to eq("http://www.lucé.fr/")
    end

    it "handles punycode" do
      normalized = described_class.normalize("https://xn--mairie-saint-l-epb.fr/")
      expect(normalized).to eq("https://mairie-saint-lô.fr/")
    end

    it "normalizes redundant slashes" do
      normalized = described_class.normalize("http://example.com//folder///page.html")
      expect(normalized).to eq("http://example.com/folder/page.html")
    end

    it "handles URLs with paths that attempt to go above root" do
      normalized = described_class.normalize("http://example.com/a/../../../page.html")
      expect(normalized).to eq("http://example.com/page.html")
    end

    it "normalizes URLs with encoded characters" do
      normalized = described_class.normalize("http://example.com/folder/page%20with%20spaces.html")
      expect(normalized).to eq("http://example.com/folder/page%20with%20spaces.html")
    end

    it "preserves URL-encoded characters in paths" do
      normalized = described_class.normalize("http://example.com/%C3%A9t%C3%A9.html")
      expect(normalized).to eq("http://example.com/%C3%A9t%C3%A9.html")
    end

    it "preserves trailing slashes in paths" do
      url_without_slash = described_class.normalize("http://example.com/path/page")
      url_with_slash = described_class.normalize("http://example.com/path/page/")
      expect(url_without_slash.to_s).to eq("http://example.com/path/page")
      expect(url_with_slash.to_s).to eq("http://example.com/path/page/")
    end

    it "preserves the original scheme" do
      normalized = described_class.normalize("https://example.com/page.html")
      expect(normalized).to eq("https://example.com/page.html")
    end

    context "when normalizing different URLs that refer to the same resource" do
      let(:urls) do
        [
          "http://example.com/folder/page.html",
          "http://example.com/folder/../folder/page.html",
          "http://example.com/folder/./page.html",
          "http://example.com//folder/page.html",
          "http://example.com/folder//page.html",
          "http://example.com/folder/other/../page.html"
        ]
      end

      it "normalizes all equivalent URLs to the same form" do
        normalized_urls = urls.map { |url| described_class.normalize(url).to_s }
        expect(normalized_urls.uniq.size).to eq(1)
        expect(normalized_urls.first).to eq("http://example.com/folder/page.html")
      end
    end

    it "raises InvalidUriError for malformed URIs like maitlo:accueil@example.com" do
      expect { described_class.normalize("maitlo:accueil@example.com") }.to raise_error(Addressable::URI::InvalidURIError)
    end

    it "handles paths with a colon preceded by percent-encoded characters" do
      normalized = described_class.normalize("https://www.example.com/Accessibilit%c3%a9-:-partiellement-conforme/9/")
      expect(normalized).to eq("https://www.example.com/Accessibilit%C3%A9-:-partiellement-conforme/9/")
    end
  end

  describe ".safe_external_url" do
    it "returns the URL for an https URL" do
      expect(described_class.safe_external_url("https://example.com")).to eq("https://example.com")
    end

    it "returns the URL for an http URL" do
      expect(described_class.safe_external_url("http://example.com")).to eq("http://example.com")
    end

    it "returns nil for an unsupported scheme" do
      expect(described_class.safe_external_url("javascript:alert(1)")).to be_nil
    end

    it "returns nil for a malformed URL" do
      expect(described_class.safe_external_url("not a url")).to be_nil
    end
  end

  describe ".root_from" do
    it "returns path for root URL" do
      url = described_class.root_from("http://example.com")
      expect(url).to eq("http://example.com/")
    end

    it "preserves trailing slash" do
      url = described_class.root_from("http://example.com/path/")
      expect(url).to eq("http://example.com/path/")
    end

    it "returns path for nested file" do
      url = described_class.root_from("http://example.com/path/to/file.pdf")
      expect(url).to eq("http://example.com/path/to/")
    end

    it "returns path for nested page" do
      url = described_class.root_from("http://example.com/path/to/page")
      expect(url).to eq("http://example.com/path/to/")
    end

    it "returns path without query" do
      url = described_class.root_from("http://example.com/path/with?a-query-string")
      expect(url).to eq("http://example.com/path/")
    end
  end

  describe ".normalized_url" do
    {
      "http://site.fr" => "site.fr",
      "http://site.fr/" => "site.fr",
      "https://site.fr/" => "site.fr",
      "https://www.site.fr/" => "site.fr",
      "https://SITE.fr/" => "site.fr",
      "https://site.fr:443/" => "site.fr",
      "https://site.fr/#contact" => "site.fr",
      "https://site.fr./" => "site.fr",
      "https://site.fr:8080/" => "site.fr", # Not wanted: another port is another server, should stay distinct
      "https://site.fr/?utm=1" => "site.fr",
      "https://user@site.fr/" => "site.fr",
      "  https://site.fr/  " => "site.fr",
      "https://site.fr/p?id=1" => "site.fr/p", # Not wanted: different query strings are different pages
      "https://site.fr/page" => "site.fr/page",
      "https://site.fr//page" => "site.fr/page",
      "https://site.fr/a/../page" => "site.fr/page",
      "https://site.fr/~user" => "site.fr/~user",
      "https://site.fr/%7Euser" => "site.fr/~user",
      "https://xn--rez-dma.fr/" => "rezé.fr",
      "https://rezé.fr/" => "rezé.fr",
      "https://site.fr/page/" => "site.fr/page/",
      "https://site.fr/Page" => "site.fr/Page",
      "https://www2.site.fr/" => "www2.site.fr",
      "https://example.com:abc" => ""
    }.each do |url, expected_normalized_url|
      it "returns #{expected_normalized_url.inspect} for #{url.inspect}" do
        expect(described_class.normalized_url(url)).to eq(expected_normalized_url)
      end
    end
  end


  describe "#initialize" do
    it "creates a Link with href and text" do
      link = described_class.new(href: "https://example.com", text: "Example")
      expect(link.href).to eq("https://example.com/")
      expect(link.text).to eq("Example")
    end

    it "converts href to string" do
      link = described_class.new(href: URI("https://example.com/"), text: "Example")
      expect(link.href).to be_a(String)
      expect(link.href).to eq("https://example.com/")
    end

    it "squishes text" do
      link = described_class.new(href: "https://example.com", text: "  Example  Text  ")
      expect(link.text).to eq("Example Text")
    end

    it "handles nil text" do
      link = described_class.new(href: "https://example.com", text: nil)
      expect(link.text).to eq("")
    end

    it "handles //" do
      link = described_class.new(href: "https://example.com//", text: nil)
      expect(link.href).to eq("https://example.com/")
    end
  end
end
