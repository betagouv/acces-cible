# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Audits ordering" do
  subject(:get_audits) { get audits_path(sort:) }

  let(:user) { create(:user) }
  let(:alpha) { create(:site, team: user.team, audits: [], url: "https://alpha.gouv.fr") }
  let(:beta) { create(:site, team: user.team, audits: [], url: "https://beta.gouv.fr") }
  let!(:alpha_audit) { create(:audit, :completed, site: alpha, user:) }
  let!(:beta_audit) { create(:audit, :completed, site: beta, user:) }

  before { login_as(user) }

  def listed_sites
    Nokogiri::HTML(response.body).css("tbody th").map { it.text.strip }
  end

  context "when sorting by site" do
    let(:sort) { { site: "desc" } }

    it "sorts alphabetically" do
      get_audits

      expect(listed_sites).to eq(%w[beta.gouv.fr alpha.gouv.fr])
    end
  end

  context "when sorting by a check column" do
    let(:sort) { { plan: "desc" } }

    before { beta_audit.checks.find_by!(type: "Checks::AnalyzePlan").update!(found: true) }

    it "sorts by the result of the check" do
      get_audits

      expect(listed_sites).to eq(%w[beta.gouv.fr alpha.gouv.fr])
    end
  end

  context "when sorting by a score" do
    let(:sort) { { legal_obligations: "asc" } }

    before do
      alpha_audit.update!(legal_obligation_score: 3)
      beta_audit.update!(legal_obligation_score: 1)
    end

    it "sorts by the score" do
      get_audits

      expect(listed_sites).to eq(%w[beta.gouv.fr alpha.gouv.fr])
    end
  end

  context "when sorting by tags" do
    let(:sort) { { tags: "asc" } }

    before do
      alpha.tags << create(:tag, name: "zebra", team: user.team)
      beta.tags << create(:tag, name: "agile", team: user.team)
    end

    it "sorts by the tag names" do
      get_audits

      expect(listed_sites).to eq(%w[beta.gouv.fr alpha.gouv.fr])
    end
  end

  context "when sorting by every sortable column" do
    AuditColumns::ALL.each do |column|
      it "sorts by #{column} without error" do
        get audits_path(sort: { column => "asc" }, filter: { scope: "team" })

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
