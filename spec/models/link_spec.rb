require "rails_helper"

RSpec.describe Link do
  describe "#initialize" do
    it "creates a Link with href and text" do
      link = Link.new(href: "https://example.com", text: "Example")
      expect(link.href).to eq("https://example.com")
      expect(link.text).to eq("Example")
    end

    it "converts href to string" do
      link = Link.new(href: URI("https://example.com"), text: "Example")
      expect(link.href).to eq("https://example.com")
    end

    it "squishes text" do
      link = Link.new(href: "https://example.com", text: "  Example  Text  ")
      expect(link.text).to eq("Example Text")
    end

    it "handles nil text" do
      link = Link.new(href: "https://example.com", text: nil)
      expect(link.text).to eq("")
    end
  end

  describe "#to_str" do
    it "returns the href" do
      link = Link.new(href: "https://example.com", text: "Example")
      expect(link.to_str).to eq("https://example.com")
    end
  end

  describe "#==" do
    it "considers links equal if they have the same href" do
      link1 = Link.new(href: "https://example.com", text: "Example 1")
      link2 = Link.new(href: "https://example.com", text: "Example 2")
      expect(link1).to eq(link2)
    end

    it "considers links different if they have different hrefs" do
      link1 = Link.new(href: "https://example1.com", text: "Example")
      link2 = Link.new(href: "https://example2.com", text: "Example")
      expect(link1).not_to eq(link2)
    end
  end
end
