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

    context "when site has no launched audit yet" do
      let(:site) { create(:site, :draft, team:) }

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
  end
end
