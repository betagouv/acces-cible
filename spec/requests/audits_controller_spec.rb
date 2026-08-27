# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Audits" do
  let!(:user) { create(:user) }
  let(:team) { user.team }
  let!(:site) { create(:site, team:) }
  let(:last_audit) { Audit.last }

  before { login_as(user) }

  describe "POST /sites/:site_id/audits" do
    subject(:post_audit) { post site_audits_path(site) }

    it "creates an audit and redirects to the site" do
      expect { post_audit }.to change(Audit, :count).by(1)

      expect(response).to redirect_to(site)
    end

    it "assigns the current user to the audit" do
      post_audit

      expect(last_audit.user).to eq(user)
    end

    it "doesn't create an audit batch for a single relaunch" do
      expect { post_audit }.not_to change(AuditBatch, :count)

      expect(last_audit.audit_batch).to be_nil
    end

    context "when site belongs to another team" do
      let(:site) { create(:site, team: create(:team)) }

      it "returns not found" do
        post_audit

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /audits" do
    subject(:get_audits) { get audits_path }

    it "returns success" do
      get_audits

      expect(response).to have_http_status(:ok)
    end

    context "when the current user has audited a site" do
      let!(:audit) { create(:audit, :completed, site:, user:) }

      it "lists the site" do
        get_audits

        expect(response.body).to include(site.normalized_url)
      end

      it "makes the row navigate to that audit" do
        get_audits

        row = Nokogiri::HTML(response.body).at_css("tbody tr")

        expect(row["data-row-link-url-value"]).to eq(site_audit_path(site, audit))
      end
    end

    context "when the site was only audited by a teammate" do
      let(:teammate) { create(:user, siret: user.siret) }
      let!(:audit) { create(:audit, :completed, site:, user: teammate) }

      it "doesn't list the site" do
        get_audits

        expect(response.body).not_to include(site.normalized_url)
      end
    end

    context "when a teammate audited the site more recently than the current user" do
      let(:teammate) { create(:user, siret: user.siret) }
      let!(:my_audit) { create(:audit, site:, user:, created_at: 2.days.ago, completed_at: 2.days.ago) }
      let!(:teammate_audit) { create(:audit, site:, user: teammate, created_at: 1.day.ago, completed_at: 1.day.ago) }

      it "shows the current user's own latest audit date" do
        get_audits

        row = Nokogiri::HTML(response.body).at_css("tbody tr")

        expect(row.text).to include(I18n.l(my_audit.completed_at.in_time_zone, format: :complete))
        expect(row.text).not_to include(I18n.l(teammate_audit.completed_at.in_time_zone, format: :complete))
      end
    end

    context "when a site belongs to another team" do
      let(:other_team) { create(:team) }
      let(:other_site) { create(:site, team: other_team) }
      let!(:audit) { create(:audit, :completed, site: other_site, user: create(:user, siret: other_team.siret)) }

      it "doesn't list the site" do
        get_audits

        expect(response.body).not_to include(other_site.normalized_url)
      end
    end

    context "with filter[scope]=team" do
      subject(:get_audits) { get audits_path(filter: { scope: "team" }) }

      let(:site) { create(:site, team:, audits: []) }

      context "when the site was only audited by a teammate" do
        let(:teammate) { create(:user, siret: user.siret) }
        let!(:audit) { create(:audit, :completed, site:, user: teammate) }

        it "lists the site" do
          get_audits

          expect(response.body).to include(site.normalized_url)
        end
      end

      context "when a teammate audited the site more recently than the current user" do
        let(:teammate) { create(:user, siret: user.siret) }
        let!(:my_audit) { create(:audit, site:, user:, created_at: 2.days.ago, completed_at: 2.days.ago) }
        let!(:teammate_audit) { create(:audit, site:, user: teammate, created_at: 1.day.ago, completed_at: 1.day.ago) }

        it "shows the team's latest audit, regardless of who launched it" do
          get_audits

          row = Nokogiri::HTML(response.body).at_css("tbody tr")

          expect(row.text).to include(I18n.l(teammate_audit.completed_at.in_time_zone, format: :complete))
          expect(row.text).not_to include(I18n.l(my_audit.completed_at.in_time_zone, format: :complete))
        end
      end

      context "when a site belongs to another team" do
        let(:other_team) { create(:team) }
        let(:other_site) { create(:site, team: other_team) }
        let!(:audit) { create(:audit, :completed, site: other_site, user: create(:user, siret: other_team.siret)) }

        it "doesn't list the site" do
          get_audits

          expect(response.body).not_to include(other_site.normalized_url)
        end
      end
    end
  end

  describe "GET /audits/csv_export" do
    subject(:get_csv) { get csv_export_audits_path(format: :csv), params: request_params }

    let(:tag) { create(:tag, team:) }
    let!(:site) { create(:site, team:, audits: [build(:audit, :completed, user:)]) }
    let!(:other_site) { create(:site, team:, tag_ids: [tag.id], audits: [build(:audit, :completed, user:)]) }

    let(:request_params) { {} }
    let(:csv_without_bom) { response.body.delete_prefix(AuditCsvExport::UTF8_BOM) }

    it "returns CSV content" do
      get_csv

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Content-Disposition"]).to include("sites_")
      expect(response.body).to start_with(AuditCsvExport::UTF8_BOM)
    end

    it "includes sites data in CSV" do
      get_csv

      csv = CSV.parse(csv_without_bom, col_sep: ";", headers: true)
      expect(csv.count).to eq(2)
      expect(csv[0]["Adresse du site"]).to eq(other_site.normalized_url)
      expect(csv[1]["Adresse du site"]).to eq(site.normalized_url)
    end

    context "when filtering by site ids" do
      let(:request_params) { { id: [other_site.id] } }

      it "returns only selected sites" do
        get_csv

        csv = CSV.parse(csv_without_bom, col_sep: ";", headers: true)
        expect(csv.count).to eq(1)
        expect(csv.first["Adresse du site"]).to eq(other_site.normalized_url)
      end
    end

    context "when filtering by tag id" do
      let(:request_params) { { filter: { tag_id: tag.id } } }

      it "returns only tagged sites" do
        get_csv

        csv = CSV.parse(csv_without_bom, col_sep: ";", headers: true)
        expect(csv.count).to eq(1)
        expect(csv.first["Adresse du site"]).to eq(other_site.normalized_url)
      end
    end
  end

  describe "GET /sites/:site_id/audits/:id" do
    subject(:get_audit) { get site_audit_path(site, audit) }

    let(:audit) { create(:audit, :without_checks, site:) }

    it "returns success" do
      get_audit

      expect(response).to have_http_status(:ok)
    end

    context "when site belongs to another team" do
      let(:other_team) { create(:team) }
      let(:site) { create(:site, team: other_team) }
      let(:audit) { create(:audit, :without_checks, site:) }

      it "returns not found" do
        get_audit

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
