require "rails_helper"

RSpec.describe Site do
  subject { build(:site, url:) }

  let(:url) { "https://example.com/" }

  it { should be_valid }

  describe "associations" do
    it { should belong_to(:team).touch(true) }
    it { should have_many(:audits).dependent(:destroy) }

    it { should have_many(:site_tags).dependent(:destroy) }
    it { should have_many(:tags).through(:site_tags) }
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
      let!(:existing_site) { create(:site, url:) }

      it "finds site with historical URLs" do
        new_url = "https://new-example.com"
        existing_site.update(url: new_url)
        expect(described_class.find_by_url(url: new_url)).to eq(existing_site)
      end
    end

    context "when URL contains unicode" do
      let!(:existing_site) { create(:site, url:) }
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

  describe "friendly_id" do
    let(:url) { "https://example.com/path?query=1" }
    let(:site) { create(:site, url:) }

    it "generates slug from url_without_scheme_and_www" do
      expect(site.slug).to be_present
      expect(site.slug).to eq(site.url_without_scheme_and_www.parameterize)
    end

    it "maintains history of slugs" do
      old_slug = site.slug
      new_url = "https://new-example.com"

      create(:audit, :completed, site:, url: new_url)
      site.set_current_audit!

      expect(site.reload.slug).to eq("new-example-com")
      expect(described_class.friendly.find(old_slug)).to eq(site)
    end
  end

  describe "#actual_current_audit" do
    subject(:site) { create(:site) }

    context "with a freshly created site" do
      it "returns the initial audit" do
        expect(site.actual_current_audit).to eq(site.audits.first)
      end
    end

    context "when there are completed audits" do
      let!(:old_audit) { create(:audit, :completed, site:, completed_at: 2.days.ago) }
      let!(:newest_audit) { create(:audit, :completed, site:, completed_at: 1.day.ago) }

      it "returns the newest completed audit" do
        expect(site.reload.actual_current_audit).to eq(newest_audit)
      end
    end

    context "when initial audit is incomplete but other audits are completed" do
      let!(:completed_audit) { create(:audit, :completed, site:, completed_at: 1.day.ago) }

      it "returns the completed audit" do
        expect(site.actual_current_audit).to eq(completed_audit)
      end
    end

    context "when no audits are completed" do
      let!(:newer_audit) { create(:audit, site:, completed_at: nil, created_at: 1.day.from_now) }

      it "returns the newest audit by creation date" do
        expect(site.actual_current_audit).to eq(newer_audit)
      end
    end
  end

  describe "#set_current_audit!" do
    subject(:site) { create(:site) }

    let(:initial_audit) { site.audits.first }

    context "when there are multiple audits" do
      subject(:site) { create(:site) }

      it "marks the newest audit as current" do
        old_audit = site.audit
        newest_audit = create(:audit, site:, completed_at: 1.day.ago)
        expect { site.set_current_audit! }.to change { newest_audit.reload.current }.from(false).to(true)
          .and change { old_audit.reload.current }.from(true).to(false)
      end
    end

    context "when the actual current audit is already marked as current" do
      it "does not change anything" do
        initial_audit.update(current: true)
        expect { site.set_current_audit! }.not_to change { initial_audit.reload.current }
      end
    end

    context "when there are incomplete audits only" do
      let!(:newest_audit) { create(:audit, site:, completed_at: nil, created_at: 1.day.from_now) }

      it "marks the newest audit as current" do
        expect { site.set_current_audit! }.to change { newest_audit.reload.current }.from(false).to(true)
      end
    end

    context "when there are both completed and incomplete audits" do
      let!(:newest_completed_audit) { create(:audit, :completed, site:, completed_at: 2.days.ago) }
      let!(:newest_incomplete_audit) { create(:audit, site:, completed_at: nil, created_at: 1.day.from_now) }

      it "marks the newest completed audit as current" do
        expect { site.set_current_audit! }.to change { newest_completed_audit.reload.current }.from(false).to(true)
        expect(newest_incomplete_audit.reload.current).to be false
      end
    end
  end
end
