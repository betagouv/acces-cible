require "rails_helper"

RSpec.describe Site do
  subject { build(:site, url:) }

  let(:url) { "https://example.com/" }

  it { is_expected.to be_valid }

  describe "associations" do
    it { is_expected.to belong_to(:team).touch(true) }
    it { is_expected.to have_many(:audits).dependent(:destroy) }

    it { is_expected.to have_many(:site_tags).dependent(:destroy) }
    it { is_expected.to have_many(:tags).through(:site_tags) }
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
