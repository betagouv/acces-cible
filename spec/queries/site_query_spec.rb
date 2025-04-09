require "rails_helper"

RSpec.describe SiteQuery do
  subject(:query) { described_class.new(Site.all) }

  describe "#order_by" do
    subject(:result) { query.order_by(key, direction:) }

    let(:key) { nil }
    let(:direction) { nil }

    context "when sort is empty" do
      let!(:site1) { create(:site) }
      let!(:site2) { create(:site) }
      let!(:site3) { create(:site) }

      it "sorts by latest audit check date in ascending order" do
        # Create audits with different checked_at times
        create(:audit, :passed, site: site1, checked_at: 3.days.ago)
        create(:audit, :passed, site: site2, checked_at: 1.day.ago)
        create(:audit, :passed, site: site3, checked_at: 2.days.ago)

        expect(result.ids).to eq([site1.id, site3.id, site2.id])
      end
    end

    context "when sorting by :url" do
      let(:key) { :url }
      let(:direction) { :asc }

      # Create audits with domains that will sort alphabetically
      let!(:apple) { create(:audit, :passed, url: "https://apple.com") }
      let!(:banana) { create(:audit, :passed, url: "https://banana.org") }
      let!(:carrot) { create(:audit, :passed, url: "https://carrot.io") }
      let(:expected_ids) { [apple.site_id, banana.site_id, carrot.site_id] }

      context "and order is ascending" do
        it "sorts sites by their URLs in ascending order" do
          expect(result.ids).to eq(expected_ids)
        end

        it "ignores protocol and www prefix when sorting" do
          create(:audit, :passed, site: banana.site, url: "http://www.banana.org")

          expect(result.ids).to eq(expected_ids)
        end

        it "handles multiple different URLs for the same site" do
          create(:audit, :passed, site: apple.site, url: "https://www.apple-support.com")

          expect(result.ids).to eq(expected_ids)
        end
      end

      context "and order is descending" do
        let(:direction) { :desc }

        it "sorts sites by their URLs in descending order" do
          expect(result.ids).to eq(expected_ids.reverse)
        end
      end
    end

    context "when sorting by :checked_at" do
      let(:key) { :checked_at }
      let(:direction) { :desc }

      let!(:site1) { create(:site) }
      let!(:site2) { create(:site) }
      let!(:site3) { create(:site) }

      it "sorts by latest audit check date in descending order" do
        # Audits with different checked_at times
        create(:audit, :passed, site: site1, checked_at: 3.days.ago)
        create(:audit, :passed, site: site2, checked_at: 1.day.ago)
        create(:audit, :passed, site: site3, checked_at: 2.days.ago)

        expect(result.ids).to eq([site2.id, site3.id, site1.id])
      end

      it "handles multiple audits per site by using the most recent one" do
        # Create multiple audits for each site
        create(:audit, :passed, site: site1, checked_at: 5.days.ago)
        create(:audit, :passed, site: site1, checked_at: 1.day.ago) # Most recent for site1

        create(:audit, :passed, site: site2, checked_at: 4.days.ago)
        create(:audit, :passed, site: site2, checked_at: 3.days.ago) # Most recent for site2

        create(:audit, :passed, site: site3, checked_at: 2.days.ago) # Most recent for site3

        expect(result.ids).to eq([site1.id, site3.id, site2.id])
      end
    end
  end
end
