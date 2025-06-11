require "rails_helper"

RSpec.describe "Sites" do
  let!(:user) { create(:user) }
  let(:team) { user.team }

  before { login_as(user) }

  describe "POST /sites" do
    subject(:post_site) { post sites_path, params: { site: { url: } } }

    let(:url) { "https://example.com" }

    it "creates a site and schedules checks automatically" do
      expect { post_site }.to change(Site, :count).by(1)
       .and change(Audit, :count).by(1)
       .and change(Check, :count).by(Check.names.count)

      site = Site.last
      audit = site.audit
      expect(audit).to be_present
      expect(audit.status).to eq("pending")
      expect(RunAuditJob).to have_been_enqueued.with(audit)

      expect(response).to redirect_to(site_path(site))
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end

    context "when URL already exists" do
      it "doesn't create a duplicate site" do
        existing_site = create(:site, url:, team:)

        expect { post_site }.not_to change(Site, :count)

        expect(response).to redirect_to(site_path(existing_site))
      end
    end

    context "when URL is invalid" do
      let(:url) { "invalid-url" }

      it "doesn't create a site and renders the form again" do
        allow_any_instance_of(Site).to receive(:valid?).and_return(false) # rubocop:disable RSpec/AnyInstance

        post_site
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /sites/upload" do
    subject(:upload_sites) { post upload_sites_path, params: { site_upload: { file: } } }

    let(:file) { fixture_file_upload("sites.csv", "text/csv") }

    it "schedules audits and redirects to sites index" do
      upload_mock = instance_double(SiteUpload, save: true, count: 2)
      allow(SiteUpload).to receive(:new).and_return(upload_mock)

      expect { upload_sites }.to have_enqueued_job(ScheduleAuditsJob)

      expect(response).to redirect_to(sites_path)
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(flash[:notice]).to include("2")
    end

    context "when upload is invalid" do
      it "returns :unprocessable_entity" do
        allow_any_instance_of(SiteUpload).to receive(:save).and_return(false) # rubocop:disable RSpec/AnyInstance

        upload_sites
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
