require "rails_helper"

RSpec.describe SiteQuery do
  subject(:query) { described_class.new(Site.all) }

  describe "#sort_by" do
    context "when sorting by :url" do
      # Create audits with domains that will sort alphabetically
      let!(:apple) { create(:site, url: "https://apple.com") }
      let!(:banana) { create(:site, url: "https://banana.org") }
      let!(:carrot) { create(:site, url: "https://carrot.io") }

      it "sorts sites by their URLs in ascending order" do
        result = query.sort_by(:url, direction: "ASC")
        expect(result.to_a.map(&:id)).to eq([apple.id, banana.id, carrot.id])
      end

      it "sorts sites by their URLs in descending order" do
        result = query.sort_by(:url, direction: "DESC")
        # Match expected order based on domain names
        expect(result.to_a.map(&:id)).to eq([carrot.id, banana.id, apple.id])
      end

      it "ignores protocol and www prefix when sorting" do
        create(:audit, site: banana, url: "http://www.banana.org")

        result = query.sort_by(:url, direction: "ASC")
        expect(result.to_a.map(&:id)).to eq([apple.id, banana.id, carrot.id])
      end

      it "handles multiple different URLs for the same site" do
        # Add a second URL for apple
        create(:audit, site: apple, url: "https://www.apple-support.com")

        # The sorting should use the URL that sorts first alphabetically after stripping prefixes
        result = query.sort_by(:url, direction: "ASC")
        expect(result.to_a.map(&:id)).to eq([apple.id, banana.id, carrot.id])
      end
    end

    context "when using default sorting" do
      let!(:site1) { create(:site) }
      let!(:site2) { create(:site) }
      let!(:site3) { create(:site) }

      it "sorts by latest audit check date in ascending order" do
        # Create audits with different checked_at times
        create(:audit, site: site1, checked_at: 3.days.ago)
        create(:audit, site: site2, checked_at: 1.day.ago)
        create(:audit, site: site3, checked_at: 2.days.ago)

        result = query.sort_by(:created_at, direction: "ASC")
        expect(result.map(&:id)).to eq([site1.id, site3.id, site2.id])
      end

      it "sorts by latest audit check date in descending order" do
        # Create audits with different checked_at times
        create(:audit, site: site1, checked_at: 3.days.ago)
        create(:audit, site: site2, checked_at: 1.day.ago)
        create(:audit, site: site3, checked_at: 2.days.ago)

        result = query.sort_by(:created_at, direction: "DESC")
        expect(result.map(&:id)).to eq([site2.id, site3.id, site1.id])
      end

      it "puts sites with no audits at the end and sorts by created_at" do
        # Create audits for only two sites
        create(:audit, site: site1, checked_at: 2.days.ago)
        create(:audit, site: site2, checked_at: 1.day.ago)
        # site3 has no audits

        result = query.sort_by(:created_at, direction: "ASC")
        expect(result.map(&:id)).to include(site3.id)
        expect(result.map(&:id).last).to eq(site3.id)
      end

      it "handles multiple audits per site by using the most recent one" do
        # Create multiple audits for each si
        create(:audit, site: site1, checked_at: 5.days.ago)
        create(:audit, site: site1, checked_at: 1.day.ago) # Most recent for site1

        create(:audit, site: site2, checked_at: 4.days.ago)
        create(:audit, site: site2, checked_at: 3.days.ago) # Most recent for site2

        result = query.sort_by(:created_at, direction: "DESC")
        expect(result.map(&:id)).to eq([site1.id, site2.id, site3.id])
      end
    end
  end
end
