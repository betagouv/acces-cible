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

  describe "scopes" do
    it ".sort_by_audit_date orders sites by their most recent audit checked_at date" do
      site1 = build(:site, audits: [build(:audit, checked_at: 1.day.ago)]).tap(&:save)
      site2 = build(:site, audits: [build(:audit, checked_at: 5.days.ago)]).tap(&:save)
      site3 = build(:site, audits: [build(:audit, checked_at: 2.days.ago)]).tap(&:save)

      expect(described_class.sort_by_audit_date).to eq([site1, site3, site2])
    end

    describe ".find_or_create_by_url" do
      let(:http_url) { "http://example.com" }

      context "when site with URL exists" do
        let!(:existing_site) { described_class.create(url:) }

        it "returns existing site for exact URL match" do
          expect(described_class.find_or_create_by_url(url:)).to eq(existing_site)
        end

        it "returns existing site when only scheme differs" do
          expect(described_class.find_or_create_by_url(url: http_url)).to eq(existing_site)
        end

        it "finds site with historical URLs" do
          new_url = "https://new-example.com"
          existing_site.audits.create!(url: new_url)

          expect(described_class.find_or_create_by_url(url:)).to eq(existing_site)
          expect(described_class.find_or_create_by_url(url: new_url)).to eq(existing_site)
        end
      end

      context "when site does not exist" do
        it "creates a new site with audit" do
          expect {
            site = described_class.find_or_create_by_url(url:)
            expect(site).to be_persisted
            expect(site.audit.url).to eq(url)
          }.to change(described_class, :count).by(1)
          .and change(Audit, :count).by(1)
        end
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
