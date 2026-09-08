require "rails_helper"

RSpec.describe "Sites" do
  let!(:user) { create(:user) }
  let(:team) { user.team }

  before { login_as(user) }

  describe "GET /sites/:id" do
    subject(:get_site) { get site_path(site) }

    let(:site) { create(:site, :with_data, team:) }

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

    context "when redirected URLs contain HTML" do
      let(:site) { create(:site, :with_data, team:) }
      let(:reachable_check) { site.last_audit.reachable }

      before do
        site.last_audit.update_column(:home_page_url, "https://safe.example")
        reachable_check.update!(
          data: {
            original_url: %(<img src=x onerror=alert('xss-1')>),
            redirect_url: %(<script>alert('xss-2')</script>)
          }
        )
      end

      it "escapes the redirected URLs in the message" do
        get_site

        expect(response.body).not_to include("<img src=x onerror=alert('xss-1')>")
        expect(response.body).not_to include("<script>alert('xss-2')</script>")
        expect(response.body).to include("xss-1")
        expect(response.body).to include("xss-2")
      end
    end
  end

  describe "POST /sites" do
    subject(:post_site) { post sites_path, params: { site: { url: } } }

    let(:url) { "https://example.com" }
    let(:site) { Site.last }
    let(:audit) { site.last_audit }

    it "creates a site and schedules checks automatically" do
      expect { post_site }.to change(Site, :count).by(1)
                                                  .and change(Audit, :count).by(1)
                                                                            .and change(Check, :count).by(Check.names.count)

      expect(audit).to be_present
      expect(audit).to be_pending

      expect(response).to redirect_to(site_path(site))
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end

    it "assigns current user to the new audit" do
      post_site

      audit = Site.last.last_audit
      expect(audit.user).to eq(user)
    end

    context "when URL already exists" do
      let!(:existing_site) { create(:site, url:, team:) }

      it "doesn't create a duplicate site" do
        expect { post_site }.not_to change(Site, :count)

        expect(response).to redirect_to(site_path(existing_site))
      end

      it "assigns current user to the new audit" do
        post_site

        expect(existing_site.last_audit.user).to eq(user)
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
      upload_mock = instance_double(SiteUpload, save: true, count: 2)
      allow(SiteUpload).to receive(:new).and_return(upload_mock)

      upload_sites

      expect(response).to redirect_to(audits_path)
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(flash[:notice]).to eq("L'import du fichier CSV a commencé. 2 sites seront ajoutés progressivement.")
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
