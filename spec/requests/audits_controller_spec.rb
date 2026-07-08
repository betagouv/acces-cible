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

    it "creates an audit and redirects to it" do
      expect { post_audit }.to change(Audit, :count).by(1)

      expect(response).to redirect_to([site, last_audit])
    end

    it "assigns the current user to the audit" do
      post_audit

      expect(last_audit.user).to eq(user)
    end

    context "when site belongs to another team" do
      let(:site) { create(:site, team: create(:team)) }

      it "returns not found" do
        post_audit

        expect(response).to have_http_status(:not_found)
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
