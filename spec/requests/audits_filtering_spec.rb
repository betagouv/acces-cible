# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Audits filtering" do
  subject(:get_audits) { get audits_path(filter:) }

  let(:user) { create(:user) }
  let(:site) { create(:site, team: user.team, audits: []) }
  let(:other_site) { create(:site, team: user.team, audits: []) }
  let!(:matching_audit) { create(:audit, :completed, site:, user:) }
  let!(:other_audit) { create(:audit, :completed, site: other_site, user:) }

  before { login_as(user) }

  def update_check(audit, type, **attributes)
    audit.checks.find_by!(type: "Checks::#{type}").update!(**attributes)
  end

  def listed_sites
    Nokogiri::HTML(response.body).css("tbody th").map { it.text.strip }
  end

  shared_examples "a filter" do
    it "lists only matching evaluations" do
      get_audits

      expect(listed_sites).to eq([site.normalized_url.truncate(ApplicationHelper::TRUNCATION_LENGTH)])
    end
  end

  context "without filters" do
    let(:filter) { {} }

    it "lists every evaluation" do
      get_audits

      expect(listed_sites).to contain_exactly(site.normalized_url, other_site.normalized_url)
    end
  end

  context "with a blank filter value" do
    let(:filter) { { declared_level: "", accessibility_page: "" } }

    it "ignores it" do
      get_audits

      expect(listed_sites).to contain_exactly(site.normalized_url, other_site.normalized_url)
    end
  end

  context "when filtering by declared level" do
    let(:filter) { { declared_level: "partiellement" } }

    before do
      update_check(matching_audit, "AccessibilityMention", data: { mention: "partiellement" })
      update_check(other_audit, "AccessibilityMention", data: { mention: "totalement" })
    end

    it_behaves_like "a filter"
  end

  context "when filtering by reachability" do
    before do
      update_check(matching_audit, "Reachable", found: true, data: { original_url: "a", redirect_url: "b" })
      update_check(other_audit, "Reachable", found: true, data: {})
    end

    context "with redirected sites" do
      let(:filter) { { reachable: "redirected" } }

      it_behaves_like "a filter"
    end

    context "with reachable sites" do
      let(:filter) { { reachable: "reachable" } }

      it "lists only sites without redirection" do
        get_audits

        expect(listed_sites).to eq([other_site.normalized_url])
      end
    end

    context "with unreachable sites" do
      let(:filter) { { reachable: "unreachable" } }

      before { update_check(matching_audit, "Reachable", found: false, data: nil) }

      it_behaves_like "a filter"
    end
  end

  context "when filtering by presence of a legal obligation" do
    before do
      update_check(matching_audit, "AnalyzePlan", found: true)
    end

    context "with present" do
      let(:filter) { { plan: "true" } }

      it_behaves_like "a filter"
    end

    context "with absent" do
      let(:filter) { { plan: "false" } }

      it "lists only evaluations without it" do
        get_audits

        expect(listed_sites).to eq([other_site.normalized_url])
      end
    end
  end

  context "when filtering by declaration quality criterion" do
    let(:filter) { { auditor: "true", contact_form: "true" } }

    before do
      update_check(matching_audit, "AnalyzeAccessibilityPage", data: { auditor: "ACME", contact_form: "https://example.com/contact" })
      update_check(other_audit, "AnalyzeAccessibilityPage", data: { auditor: "ACME" })
    end

    it_behaves_like "a filter"
  end

  context "when exporting to CSV" do
    subject(:get_csv) { get csv_export_audits_path(format: :csv, filter:) }

    let(:filter) { { plan: "true" } }

    before { update_check(matching_audit, "AnalyzePlan", found: true) }

    it "applies the filters" do
      get_csv

      expect(response.body).to include(site.normalized_url)
      expect(response.body).not_to include(other_site.normalized_url)
    end
  end

  context "when rendering the filters modal" do
    let(:filter) { {} }

    it "offers every filterable column" do
      get_audits

      names = Nokogiri::HTML(response.body).css("#filters-modal input[type=radio]").pluck("name").uniq

      expect(names).to match_array(AuditColumns::FILTERABLE.map { "filter[#{it}]" })
    end
  end
end
