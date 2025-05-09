require "rails_helper"

RSpec.describe Site do
  let(:url) { "https://example.com/" }

  describe "associations" do
    it { should have_many(:audits).dependent(:destroy) }
  end

  describe "delegations" do
    it { should delegate_method(:url).to(:audit) }

    it "delegates to the most recent audit" do
      site = create(:audit, url: "https://example.com").site
      new_audit = create(:audit, site:, url: "https://new-example.com")
      expect(site.reload.url).to eq(new_audit.url)
    end
  end

  describe ".find_by_url" do
    context "when url is malformed" do
      it "returns nil" do
        expect(described_class.find_by_url(url: "not a valid url")).to be_nil
      end
    end

    context "when nothing exists for that URL" do
      it "returns nil" do
        expect(described_class.find_by_url(url: "http://not-an-existing-site.com")).to be_nil
      end
    end

    context "when a site exists for that URL" do
      let!(:existing_site) { create(:site, url:) }

      it "returns existing site" do
        expect(described_class.find_by_url(url:)).to eq(existing_site)
      end
    end

    context "when a site exists with a different scheme" do
      let!(:existing_site) { create(:site, url:) }

      it "returns existing site" do
        expect(described_class.find_by_url(url: url.sub("https:", "http:"))).to eq(existing_site)
      end
    end

    context "when a site had that URL" do
      let!(:existing_site) { described_class.create(url:) }

      it "finds site with historical URLs" do
        new_url = "https://new-example.com"
        existing_site.update(url: new_url)
        expect(described_class.find_by_url(url: new_url)).to eq(existing_site)
      end
    end

    context "when URL contains unicode" do
      let!(:existing_site) { described_class.create(url:) }
      let(:url) { "https://éxâmplè.çôm/" }

      it "returns the existing site" do
        expect(described_class.find_by_url(url:)).to eq(existing_site)
      end

      it "finds by punycode url" do
        punycode_url = Addressable::URI.parse(url).normalize.to_s
        expect(described_class.find_by_url(url: punycode_url)).to eq(existing_site)
      end
    end
  end

  describe "#url_without_scheme" do
    let(:site) { build(:site) }

    before do
      allow(site).to receive(:url).and_return(url)
    end

    context "when path is empty" do
      it "returns hostname only" do
        expect(site.url_without_scheme).to eq("example.com")
      end
    end

    context "when path is not empty" do
      let(:url) { "https://example.com/path" }

      it "returns hostname and path" do
        expect(site.url_without_scheme).to eq("example.com/path")
      end
    end
  end

  describe "friendly_id" do
    let(:url) { "https://example.com/path?query=1" }
    let(:site) { create(:site, url:) }

    it "generates slug from url_without_scheme" do
      expect(site.slug).to be_present
      expect(site.slug).to eq(site.url_without_scheme.parameterize)
    end

    it "maintains history of slugs" do
      old_slug = site.slug
      new_url = "https://new-example.com"

      site.audits.create!(url: new_url, status: :passed)
      site.save!

      expect(site.reload.slug).not_to eq(old_slug)
      expect(described_class.friendly.find(old_slug)).to eq(site)
    end
  end
end
