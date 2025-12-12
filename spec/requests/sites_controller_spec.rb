require "rails_helper"

RSpec.describe "Sites" do
  let!(:user) { create(:user) }
  let(:team) { user.team }

  before { login_as(user) }

  describe "GET /sites" do
    subject(:get_sites) { get sites_path }

    it "returns success" do
      get_sites

      expect(response).to have_http_status(:ok)
    end

    context "when requesting CSV format" do
      subject(:get_csv) { get sites_path(format: :csv) }

      let!(:site) { create(:site, :checked, team:) }

      it "returns CSV content" do
        get_csv

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/csv")
        expect(response.headers["Content-Disposition"]).to include("attachment")
        expect(response.headers["Content-Disposition"]).to include("sites_")
      end

      it "includes site data in CSV" do
        get_csv

        csv = CSV.parse(response.body, col_sep: ";", headers: true)
        expect(csv.count).to eq(1)
        expect(csv.first[Audit.human(:site_url_address)]).to eq(site.url_without_scheme_and_www)
      end
    end
  end

  describe "GET /sites/:id" do
    subject(:get_site) { get site_path(site) }

    let(:site) { create(:site, :with_data, team:, name: "Example Site") }

    it "returns success" do
      get_site

      expect(response).to have_http_status(:ok)
    end

    context "when accessing with old slug" do
      it "redirects to current slug with moved_permanently status" do
        old_slug = site.slug
        site.update!(url: "https://newexample.com")

        get "/sites/#{old_slug}"

        expect(response).to redirect_to(site_path(site))
        expect(response).to have_http_status(:moved_permanently)
      end
    end

    context "when site belongs to another team" do
      let(:other_team) { create(:team) }
      let(:site) { create(:site, team: other_team) }

      it "returns not found status" do
        get_site

        expect(response).to have_http_status(:not_found)
      end
    end
  end

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
      expect(audit).to be_pending

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
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "POST /sites/upload" do
    subject(:upload_sites) { post upload_sites_path, params: { site_upload: { file: } } }

    let(:file) { fixture_file_upload("sites.csv", "text/csv") }

    it "schedules audits and redirects to sites index" do
      upload_mock = instance_double(SiteUpload, save: true)
      allow(SiteUpload).to receive(:new).and_return(upload_mock)

      upload_sites

      expect(response).to redirect_to(sites_path)
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(flash[:notice]).to include("Import démarré")
    end

    context "when upload is invalid" do
      it "returns :unprocessable_content" do
        allow_any_instance_of(SiteUpload).to receive(:save).and_return(false) # rubocop:disable RSpec/AnyInstance

        upload_sites
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
