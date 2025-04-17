require "rails_helper"

RSpec.describe "Sites" do
  describe "POST /sites" do
    subject(:post_site) { post sites_path, params: { site: { url: } } }

    let(:url) { "https://example.com" }

    it "creates a site and schedules checks automatically" do
      expect { post_site }.to change(Site, :count).by(1)
       .and change(Audit, :count).by(1)
       .and change(Check, :count).by(Check.names.count)

      expect(response).to redirect_to(site_path(Site.last))

      follow_redirect!
      expect(response).to have_http_status(:ok)

      site = Site.last
      audit = site.audit
      expect(audit).to be_present
      expect(audit.status).to eq("pending")

      expect(RunAuditJob).to have_been_enqueued.with(audit)
    end

    context "when URL already exists" do
      it "doesn't create a duplicate site" do
        existing_site = Site.create(url:)

        expect { post_site }.not_to change(Site, :count)

        expect(response).to redirect_to(site_path(existing_site))
      end
    end

    context "when URL is invalid" do
      let(:url) { "invalid-url" }

      it "returns :unprocessable_entity" do
        expect { post_site }.not_to change(Site, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
