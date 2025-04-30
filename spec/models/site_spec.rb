require "rails_helper"

RSpec.describe Site do
  let(:url) { "https://example.com/" }

  describe "associations" do
    it { should have_many(:audits).dependent(:destroy) }
  end

  describe "delegations" do
    let(:site) { create(:site) }
    let!(:audit) { create(:audit, site:, url: "https://example.com") }

    it { should delegate_method(:url).to(:audit) }
    it { should delegate_method(:url_without_scheme).to(:audit) }

    it "delegates to the most recent audit" do
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
      let!(:existing_site) { described_class.create(url:) }

      it "returns existing site" do
        expect(described_class.find_by_url(url:)).to eq(existing_site)
      end
    end

    context "when a site exists with a different scheme" do
      let!(:existing_site) { described_class.create(url:) }

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

  describe "#to_title" do
    let(:site) { create(:site, url:) }
    let!(:audit) { create(:audit, site:) }

    it "returns the URL without scheme from the latest audit" do
      expect(site.to_title).to eq(audit.url_without_scheme)
    end

    it "updates when new audit is created" do
      new_audit = create(:audit, site:, url: "https://new-example.com")
      expect(site.reload.to_title).to eq(new_audit.url_without_scheme)
    end
  end

  describe "friendly_id" do
    let(:url) { "https://example.com/path?query=1" }
    let(:site) { create(:site, url:) }

    it "generates slug from url_without_scheme" do
      expect(site.slug).to be_present
      expect(site.slug).to eq(site.audit.url_without_scheme.parameterize)
    end

    it "maintains history of slugs" do
      old_slug = site.slug
      new_url = "https://new-example.com"

      site.audits.create!(url: new_url)
      site.save!

      expect(site.reload.slug).not_to eq(old_slug)
      expect(described_class.friendly.find(old_slug)).to eq(site)
    end
  end
end
