require "rails_helper"

RSpec.describe Site do
  subject { build(:site, url:) }

  let(:url) { "https://example.com/" }

  it { is_expected.to be_valid }

  describe "URL normalization" do
    subject(:site) { create(:site, url: " HTTPS://EXAMPLE.COM/path/ ") }

    it "normalizes its URL" do
      site = create(:site, url: " HTTPS://EXAMPLE.COM/path/ ")

      expect(site.url).to eq("https://example.com/path/")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:team).touch(true) }
    it { is_expected.to have_many(:audits).dependent(:destroy) }

    it { is_expected.to have_many(:site_tags).dependent(:destroy) }
    it { is_expected.to have_many(:tags).through(:site_tags) }
  end

  describe ".with_launched_audit" do
    subject(:with_launched_audit) { described_class.with_launched_audit }

    let!(:site) { create(:site) }

    context "when another site has only draft audits" do
      before { create(:site, :draft) }

      it "excludes it" do
        expect(with_launched_audit).to eq([site])
      end
    end

    context "when the site also has a draft audit" do
      before { create(:audit, :draft, site:) }

      it "still includes it" do
        expect(with_launched_audit).to eq([site])
      end
    end
  end

  describe "#last_audit" do
    subject(:site) { create(:site) }

    context "when a draft audit is more recent" do
      let!(:launched) { site.last_audit }

      before do
        create(:audit, :draft, site:)
        site.reload
      end

      it "is ignored by both readers" do
        expect(site.last_audit).to eq(launched)
        expect(site.last_audit_without_html).to eq(launched)
      end
    end
  end

  describe "friendly_id" do
    let(:url) { "https://example.com/path?query=1" }
    let(:site) { create(:site, url:) }

    it "generates slug from normalized_url" do
      expect(site.slug).to be_present
      expect(site.slug).to eq(site.normalized_url.parameterize)
    end

    it "maintains history of slugs" do
      old_slug = site.slug
      new_url = "https://new-example.com"

      site.update!(url: new_url)

      expect(site.reload.slug).to eq("new-example-com")
      expect(described_class.friendly.find(old_slug)).to eq(site)
    end
  end
end
