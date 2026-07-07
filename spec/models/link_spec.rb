require "rails_helper"

RSpec.describe Link do
  describe ".normalize" do
    it "removes fragments from URLs" do
      normalized = described_class.normalize("http://example.com/page#section")
      expect(normalized.to_s).not_to include("#section")
    end

    it "preserves query parameters" do
      normalized = described_class.normalize("http://example.com/page?param=value")
      expect(normalized.to_s).to include("?param=value")
    end

    it "normalizes paths with doubled slashes" do
      normalized = described_class.normalize("http://example.com/folder//")
      expect(normalized.to_s).to eq("http://example.com/folder/")
    end

    it "normalizes paths with parent directory references" do
      normalized = described_class.normalize("http://example.com/folder/../page.html")
      expect(normalized.to_s).to eq("http://example.com/page.html")
    end

    it "normalizes paths with current directory references" do
      normalized = described_class.normalize("http://example.com/folder/./page.html")
      expect(normalized.to_s).to eq("http://example.com/folder/page.html")
    end

    it "normalizes paths with multiple parent directory references" do
      normalized = described_class.normalize("http://example.com/a/b/c/../../page.html")
      expect(normalized.to_s).to eq("http://example.com/a/page.html")
    end

    it "normalizes complex paths with mixed parent and current directory references" do
      normalized = described_class.normalize("http://example.com/a/./b/../c/./d/../page.html")
      expect(normalized.to_s).to eq("http://example.com/a/c/page.html")
    end

    it "handles non-standard ports" do
      normalized = described_class.normalize("http://example.com:8080/page.html")
      expect(normalized.to_s).to include(":8080")
    end

    it "doesn't include standard ports in the normalized URL" do
      normalized = described_class.normalize("http://example.com:80/page.html")
      expect(normalized.to_s).not_to include(":80")
    end

    it "handles URLs with no path" do
      normalized = described_class.normalize("http://example.com")
      expect(normalized.to_s).to eq("http://example.com/")
    end

    it "handles accented URLs" do
      normalized = described_class.normalize("http://www.lucé.fr/./..///")
      converted = "http://www.lucé.fr/"
      expect(normalized.to_s).to eq(converted)
    end

    it "handles punycode" do
      normalized = described_class.normalize("https://xn--mairie-saint-l-epb.fr/")
      converted = "https://mairie-saint-lô.fr/"
      expect(normalized.to_s).to eq(converted)
    end

    it "normalizes redundant slashes" do
      normalized = described_class.normalize("http://example.com//folder///page.html")
      expect(normalized.to_s).to eq("http://example.com/folder/page.html")
    end

    it "handles URLs with paths that attempt to go above root" do
      normalized = described_class.normalize("http://example.com/a/../../../page.html")
      expect(normalized.to_s).to eq("http://example.com/page.html")
    end

    it "normalizes URLs with encoded characters" do
      normalized = described_class.normalize("http://example.com/folder/page%20with%20spaces.html")
      expect(normalized.to_s).to eq("http://example.com/folder/page%20with%20spaces.html")
    end

    it "preserves URL-encoded characters in paths" do
      normalized = described_class.normalize("http://example.com/%C3%A9t%C3%A9.html")
      expect(normalized.to_s).to eq("http://example.com/%C3%A9t%C3%A9.html")
    end

    it "preserves trailing slashes in paths" do
      url_without_slash = described_class.normalize("http://example.com/path/page")
      url_with_slash = described_class.normalize("http://example.com/path/page/")
      expect(url_without_slash.to_s).to eq("http://example.com/path/page")
      expect(url_with_slash.to_s).to eq("http://example.com/path/page/")
    end

    it "preserves the original scheme" do
      normalized = described_class.normalize("https://example.com/page.html")
      expect(normalized.to_s).to start_with("https://")
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
      expect { described_class.normalize("maitlo:accueil@itxassou.fr") }.to raise_error(Addressable::URI::InvalidURIError)
    end

    it "handles paths with a colon preceded by percent-encoded characters" do
      normalized = described_class.normalize("https://www.ville-sussargues.fr/Accessibilit%c3%a9-:-partiellement-conforme/9/")
      expect(normalized).to include("ville-sussargues.fr")
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

  describe ".url_without_scheme_and_www" do
    subject(:url_without_scheme_and_www) { described_class.url_without_scheme_and_www(url) }

    context "when subdomain is www" do
      let(:url) { "https://www.domain.com/" }

      it "returns the hostname without www" do
        expect(url_without_scheme_and_www).to eq("domain.com")
      end
    end

    context "when subdomain is not www" do
      let(:url) { "https://sub.domain.com/" }

      it "returns the hostname with subdomain" do
        expect(url_without_scheme_and_www).to eq("sub.domain.com")
      end
    end

    context "when path is empty" do
      let(:url) { "https://www.example.com/" }

      it "returns hostname only" do
        expect(url_without_scheme_and_www).to eq("example.com")
      end
    end

    context "when path is not empty" do
      let(:url) { "https://www.example.com/path/to/page#section?query=string" }

      it "returns hostname and path" do
        expect(url_without_scheme_and_www).to eq("example.com/path/to/page")
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
