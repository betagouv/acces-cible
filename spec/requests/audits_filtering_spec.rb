# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Audits filtering" do
  subject(:get_audits) { get audits_path(filter:) }

  let(:user) { create(:user) }
  let(:site) { create(:site, team: user.team, audits: []) }
  let(:other_site) { create(:site, team: user.team, audits: []) }
  let!(:matching_audit) { create(:audit, :without_checks, :completed, site:, user:) }
  let!(:other_audit) { create(:audit, :without_checks, :completed, site: other_site, user:) }

  before { login_as(user) }

  shared_examples "a filter" do
    it "lists only matching evaluations" do
      get_audits

      expect(response.body).to include(site.normalized_url)
      expect(response.body).not_to include(other_site.normalized_url)
    end
  end

  context "without filters" do
    let(:filter) { {} }

    it "lists every evaluation" do
      get_audits

      expect(response.body).to include(site.normalized_url, other_site.normalized_url)
    end
  end

  context "with a blank filter value" do
    let(:filter) { { declared_level: "", accessibility_page: "" } }

    it "ignores it" do
      get_audits

      expect(response.body).to include(site.normalized_url, other_site.normalized_url)
    end
  end

  context "when filtering by declared level" do
    let(:filter) { { declared_level: "partiellement" } }

    before do
      create(:check, :accessibility_mention, :completed, audit: matching_audit, found: true, data: { mention: "partiellement" })
      create(:check, :accessibility_mention, :completed, audit: other_audit, found: true, data: { mention: "totalement" })
    end

    it_behaves_like "a filter"
  end

  context "when filtering by several declared levels" do
    let(:filter) { { declared_level: %w[partiellement totalement] } }

    before do
      create(:check, :accessibility_mention, :completed, audit: matching_audit, found: true, data: { mention: "partiellement" })
      create(:check, :accessibility_mention, :completed, audit: other_audit, found: true, data: { mention: "totalement" })
    end

    it "lists evaluations matching any of them" do
      get_audits

      expect(response.body).to include(site.normalized_url, other_site.normalized_url)
    end
  end

  context "when filtering by reachability" do
    let(:matching_reachable) { { found: true, data: { original_url: "a", redirect_url: "b" } } }

    before do
      create(:check, :reachable, :completed, audit: matching_audit, **matching_reachable)
      create(:check, :reachable, :completed, audit: other_audit, found: true, data: {})
    end

    context "with redirected sites" do
      let(:filter) { { reachable: "redirected" } }

      it_behaves_like "a filter"
    end

    context "with reachable sites" do
      let(:filter) { { reachable: "reachable" } }

      it "lists only sites without redirection" do
        get_audits

        expect(response.body).to include(other_site.normalized_url)
        expect(response.body).not_to include(site.normalized_url)
      end
    end

    context "with unreachable sites" do
      let(:filter) { { reachable: "unreachable" } }
      let(:matching_reachable) { { found: false, data: nil } }

      it_behaves_like "a filter"
    end
  end

  context "when filtering by presence of a legal obligation" do
    before do
      create(:check, :find_accessibility_page, :completed, audit: matching_audit, found: true)
      create(:check, :find_accessibility_page, :completed, audit: other_audit, found: true)
      create(:check, :analyze_plan, :completed, audit: matching_audit, found: true)
      create(:check, :analyze_plan, :completed, audit: other_audit, found: false)
    end

    context "with present" do
      let(:filter) { { plan: "true" } }

      it_behaves_like "a filter"
    end

    context "with absent" do
      let(:filter) { { plan: "false" } }

      it "lists only evaluations without it" do
        get_audits

        expect(response.body).to include(other_site.normalized_url)
        expect(response.body).not_to include(site.normalized_url)
      end
    end
  end

  context "when filtering by declaration quality criterion" do
    let(:filter) { { auditor: "true", contact_form: "true" } }

    before do
      create(:check, :analyze_accessibility_page, :completed, audit: matching_audit, data: { auditor: "ACME", contact_form: "https://example.com/contact" })
      create(:check, :analyze_accessibility_page, :completed, audit: other_audit, data: { auditor: "ACME" })
    end

    it_behaves_like "a filter"
  end

  context "when exporting to CSV" do
    subject(:get_csv) { get csv_export_audits_path(format: :csv, filter:) }

    let(:filter) { { plan: "true" } }

    before do
      create(:check, :find_accessibility_page, :completed, audit: matching_audit, found: true)
      create(:check, :analyze_plan, :completed, audit: matching_audit, found: true)
    end

    it "applies the filters" do
      get_csv

      expect(response.body).to include(site.normalized_url)
      expect(response.body).not_to include(other_site.normalized_url)
    end
  end
end
