require "rails_helper"

RSpec.describe SiteQuery do
  let(:query) { Site.all }
  let(:request) { {} }
  let(:params) { ActionController::Parameters.new(request) }

  describe "#order_by" do
    subject(:result) { query.order_by(params) }

    context "when sort[url]=asc" do
      let(:request) { { sort: { url: :asc } } }

      # Create audits with domains that will sort alphabetically
      let!(:apple) { create(:audit, :passed, url: "https://apple.com") }
      let!(:banana) { create(:audit, :passed, url: "https://banana.org") }
      let!(:carrot) { create(:audit, :passed, url: "https://carrot.io") }
      let(:expected_ids) { [apple.site_id, banana.site_id, carrot.site_id] }

      it "sorts sites by their URLs in ascending order" do
        expect(result.ids).to eq(expected_ids)
      end

      it "ignores protocol and www prefix" do
        create(:audit, :passed, site: banana.site, url: "http://www.banana.org")

        expect(result.ids).to eq(expected_ids)
      end

      it "handles multiple different URLs for the same site" do
        create(:audit, :passed, site: apple.site, url: "https://support.apple.com")

        expect(result.ids).to eq(expected_ids)
      end
    end

    context "when sort[url]=desc" do
      let(:request) { { sort: { url: :desc } } }

      let!(:apple) { create(:audit, :passed, url: "https://apple.com") }
      let!(:banana) { create(:audit, :passed, url: "https://banana.org") }
      let!(:carrot) { create(:audit, :passed, url: "https://carrot.io") }
      let(:expected_ids) { [apple.site_id, banana.site_id, carrot.site_id] }

      it "sorts sites by their URLs in descending order" do
        expect(result.ids).to eq(expected_ids.reverse)
      end
    end

    context "when sort is empty" do
      let(:request) { {} }
      let(:expected_ids) { [audit3.site.id, audit2.site.id, audit1.site.id] }

      let!(:audit1) { create(:audit, status: :passed, checked_at: 1.day.ago) }
      let!(:audit2) { create(:audit, status: :passed, checked_at: 2.days.ago) }
      let!(:audit3) { create(:audit, status: :passed, checked_at: 3.days.ago) }

      it "sorts by latest audit check date in descending order" do
        expect(result.ids).to eq(expected_ids)
      end
    end

    context "when sort[checked_at]=desc" do
      let(:request) { { sort: { checked_at: :desc } } }

      let!(:audit1) { create(:audit, :passed, checked_at: 1.day.ago) }
      let!(:audit2) { create(:audit, :passed, checked_at: 2.days.ago) }
      let!(:audit3) { create(:audit, :passed, checked_at: 3.days.ago) }

      it "sorts by latest audit check date in descending order" do
        expect(result.ids).to eq([audit1.site_id, audit2.site_id, audit3.site_id])
      end

      it "handles multiple audits per site by using the most recent one" do
        site1 = audit1.site
        site2 = audit2.site

        create(:audit, :passed, site: site1, checked_at: 5.days.ago)
        recent1 = create(:audit, :passed, site: site1, checked_at: 6.hours.ago)

        create(:audit, :passed, site: site2, checked_at: 4.days.ago)
        recent2 = create(:audit, :passed, site: site2, checked_at: 12.hours.ago)

        result = query.where(id: [site1.id, site2.id]).order_by(params)
        expect(result.ids).to eq([site1.id, site2.id])
      end
    end
  end

  describe "#filter_by" do
    subject(:result) { query.filter_by(params) }

    let(:request) { { search: { q: "bar" } } }

    it "returns only sites matching the query" do
      no_match = create(:site, :checked, url: "https://foo.com/")
      domain_match = create(:site, :checked, url: "https://www.bar.com/")
      path_match = create(:site, :checked, url: "https://baz.com/bar/")
      name_match = create(:site, :checked, url: "https://foo.com/", name: "Foo Bar Baz")

      expect(result.to_a).to contain_exactly(domain_match, path_match, name_match)
    end
  end

  describe "chaining methods" do
    subject(:result) { query.filter_by(params).order_by(params) }

    let(:request) { { search: { q: "bar" }, sort: { url: :desc } } }

    it "does not raise" do
      expect { result.includes(:audit).distinct.load }.not_to raise_error
    end

    it "combines sorting and filtering" do
      no_match = create(:site, :checked, url: "https://foo.com/")
      abc_match = create(:site, :checked, url: "https://abc.bar.com/")
      def_match = create(:site, :checked, url: "https://def.bar.com/")

      expect(result.to_a).to eq([def_match, abc_match])
    end
  end
end
