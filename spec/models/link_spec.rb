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

    it "treats URLs as equal if they refer to the same document" do
      url1 = described_class.normalize("http://example.com/path/page")
      url2 = described_class.normalize("http://example.com/path/page/")
      expect(url1.to_s).to eq(url2.to_s)
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
  end

  describe "#to_str" do
    it "returns the href" do
      link = described_class.new(href: "https://example.com/", text: "Example")
      expect(link.to_str).to eq("https://example.com/")
    end
  end

  describe "#==" do
    context "returns true" do
      it "if they have the same href" do
        link1 = described_class.new(href: "https://example.com/", text: "Example 1")
        link2 = described_class.new(href: "https://example.com/", text: "Example 2")
        expect(link1).to eq(link2)
      end

      it "if only the #fragment part of the href differ" do
        link1 = described_class.new(href: "https://example.com/path#fragment1", text: "Example 1")
        link2 = described_class.new(href: "https://example.com/path#fragment2", text: "Example 2")
        expect(link1).to eq(link2)
      end

      it "if relative parts resolve to the same href" do
        link1 = described_class.new(href: "https://example.com/path", text: "Example 1")
        link2 = described_class.new(href: "https://example.com/other/../path/", text: "Example 2")
        expect(link1).to eq(link2)
      end
    end

    context "returns false" do
      it "if the hosts are different" do
        link1 = described_class.new(href: "https://example1.com/", text: "Example")
        link2 = described_class.new(href: "https://example2.com/", text: "Example")
        expect(link1).not_to eq(link2)
      end

      it "if the paths are different" do
        link1 = described_class.new(href: "https://example.com/", text: "Example")
        link2 = described_class.new(href: "https://example.com/path/to/file", text: "Example")
        expect(link1).not_to eq(link2)
      end
    end
  end
end
