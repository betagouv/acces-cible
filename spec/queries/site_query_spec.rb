require "rails_helper"

RSpec.describe SiteQuery do
  let(:query) { Site.all }
  let(:request) { {} }
  let(:params) { ActionController::Parameters.new(request) }

  describe "#order_by" do
    subject(:result) { query.order_by(params) }

    context "when ordering by url" do
      let!(:apple) { create(:audit, :current, url: "https://apple.com") }
      let!(:app) { create(:audit, :current, url: "http://www.app.apple.com") }
      let!(:banana) { create(:audit, :current, url: "https://www.banana.org") }
      let!(:blog) { create(:audit, :current, url: "http://blog.beta.com") }
      let!(:carrot) { create(:audit, :current, url: "https://carrot.bio") }

      let(:expected_ids) do
        [
          app.site_id,
          apple.site_id,
          banana.site_id,
          blog.site_id,
          carrot.site_id,
        ]
      end

      context "when sort[url]=asc" do
        let(:request) { { sort: { url: :asc } } }

        it "sorts sites by their URLs in ascending order" do
          expect(result.ids).to eq(expected_ids)
        end

        it "handles multiple different URLs for the same site" do
          create(:audit, site: apple.site, url: "https://support.apple.com")

          expect(result.ids).to eq(expected_ids)
        end
      end

      context "when sort[url]=desc" do
        let(:request) { { sort: { url: :desc } } }

        it "sorts sites by their URLs in descending order" do
          expect(result.ids).to eq(expected_ids.reverse)
        end
      end
    end

    context "when sort is empty" do
      let(:request) { {} }
      let(:expected_ids) { [audit3.site_id, audit2.site_id, audit1.site_id] }

      let!(:audit1) { create(:audit, :current, completed_at: 1.day.ago) }
      let!(:audit2) { create(:audit, :current, completed_at: 2.days.ago) }
      let!(:audit3) { create(:audit, :current, completed_at: 3.days.ago) }

      it "sorts by latest audit check date in descending order" do
        expect(result.ids).to eq(expected_ids)
      end
    end

    context "when sort[completed_at]=desc" do
      let(:request) { { sort: { completed_at: :desc } } }

      let!(:audit1) { create(:audit, :current, completed_at: 1.day.ago) }
      let!(:audit2) { create(:audit, :current, completed_at: 2.days.ago) }
      let!(:audit3) { create(:audit, :current, completed_at: 3.days.ago) }

      it "sorts by latest audit check date in descending order" do
        expect(result.ids).to eq([audit1.site_id, audit2.site_id, audit3.site_id])
      end

      it "handles multiple audits per site by using the most recent one" do
        site1 = audit1.site
        site2 = audit2.site

        create(:audit, site: site1, completed_at: 6.hours.ago)
        site1.set_current_audit!

        create(:audit, site: site2, completed_at: 12.hours.ago)
        site2.set_current_audit!

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
      name_match = create(:site, :checked, url: "https://www.apple.com/", name: "Foo Bar Baz")

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
