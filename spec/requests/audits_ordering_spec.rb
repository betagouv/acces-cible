# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Audits ordering" do
  subject(:get_audits) { get audits_path(sort:) }

  let(:user) { create(:user) }
  let(:alpha) { create(:site, team: user.team, audits: [], url: "https://alpha.gouv.fr") }
  let(:beta) { create(:site, team: user.team, audits: [], url: "https://beta.gouv.fr") }
  let(:gamma) { create(:site, team: user.team, audits: [], url: "https://gamma.gouv.fr") }
  let!(:alpha_audit) { create(:audit, :without_checks, :completed, site: alpha, user:) }
  let!(:beta_audit) { create(:audit, :without_checks, :completed, site: beta, user:) }
  let!(:gamma_audit) { create(:audit, :without_checks, :completed, site: gamma, user:) }

  before { login_as(user) }

  context "when sorting by site" do
    let(:sort) { { site: "desc" } }

    it "sorts alphabetically" do
      get_audits

      expect(response.body).to match(/gamma.*beta.*alpha/m)
    end
  end

  context "when sorting by a check that is not displayed without a declaration" do
    before do
      create(:check, :find_accessibility_page, :completed, audit: alpha_audit, found: false)
      create(:check, :find_accessibility_page, :completed, audit: beta_audit, found: true)
      create(:check, :find_accessibility_page, :completed, audit: gamma_audit, found: true)
      create(:check, :analyze_plan, :completed, audit: alpha_audit, found: false)
      create(:check, :analyze_plan, :completed, audit: beta_audit, found: false)
      create(:check, :analyze_plan, :completed, audit: gamma_audit, found: true)
    end

    context "when ascending" do
      let(:sort) { { plan: "asc" } }

      it "puts the dash first, then absent, then present" do
        get_audits

        expect(response.body).to match(/alpha.*beta.*gamma/m)
      end
    end

    context "when descending" do
      let(:sort) { { plan: "desc" } }

      it "puts present first, then absent, then the dash" do
        get_audits

        expect(response.body).to match(/gamma.*beta.*alpha/m)
      end
    end
  end

  context "when sorting by compliance rate" do
    before do
      create(:check, :analyze_accessibility_page, :completed, audit: beta_audit, data: { compliance_rate: 50 })
      create(:check, :analyze_accessibility_page, :completed, audit: gamma_audit, data: { compliance_rate: 80 })
    end

    context "when ascending" do
      let(:sort) { { compliance_rate: "asc" } }

      it "treats a missing rate as the lowest" do
        get_audits

        expect(response.body).to match(/alpha.*beta.*gamma/m)
      end
    end

    context "when descending" do
      let(:sort) { { compliance_rate: "desc" } }

      it "puts a missing rate last" do
        get_audits

        expect(response.body).to match(/gamma.*beta.*alpha/m)
      end
    end
  end

  context "when sorting by auditor" do
    let(:sort) { { auditor: "asc" } }

    before do
      create(:check, :analyze_accessibility_page, :completed, audit: alpha_audit, data: { auditor: "Zed" })
      create(:check, :analyze_accessibility_page, :completed, audit: beta_audit, data: { auditor: "Acme" })
      create(:check, :analyze_accessibility_page, :completed, audit: gamma_audit, data: { auditor: "Mid" })
    end

    it "sorts alphabetically" do
      get_audits

      expect(response.body).to match(/beta.*gamma.*alpha/m)
    end
  end

  context "when sorting by a score" do
    let(:sort) { { legal_obligations: "asc" } }

    before do
      create(:check, :find_accessibility_page, :completed, audit: alpha_audit, found: false)
      create(:check, :find_accessibility_page, :completed, audit: beta_audit, found: true)
      create(:check, :find_accessibility_page, :completed, audit: gamma_audit, found: true)
      alpha_audit.update!(legal_obligation_score: 0)
      beta_audit.update!(legal_obligation_score: 1)
      gamma_audit.update!(legal_obligation_score: 3)
    end

    it "sorts by the score, the dash first" do
      get_audits

      expect(response.body).to match(/alpha.*beta.*gamma/m)
    end
  end

  context "when sorting by tags" do
    let(:sort) { { tags: "asc" } }

    before do
      alpha.tags << create(:tag, name: "zebra", team: user.team)
      beta.tags << create(:tag, name: "agile", team: user.team)
    end

    it "sorts by the tag names, untagged first" do
      get_audits

      expect(response.body).to match(/gamma.*beta.*alpha/m)
    end
  end

  context "when sorting by every sortable column" do
    AuditColumns::GROUPS.values.flatten.each do |column|
      it "sorts by #{column} without error" do
        get audits_path(sort: { column => "asc" }, filter: { scope: "team" })

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
