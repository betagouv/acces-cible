require "rails_helper"

RSpec.describe "AuditBatches" do
  include ActiveJob::TestHelper

  let!(:user) { create(:user) }
  let(:team) { user.team }

  before { login_as(user) }

  describe "GET /audit_batches/new" do
    it "shows the first step" do
      get new_audit_batch_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /audit_batches?requested_step=" do
    subject(:post_step) { post audit_batches_path, params: { requested_step: step, audit_batch: { kind: "manual", urls: ["https://example.com"] } } }

    let(:step) { "summary" }

    it "creates nothing" do
      expect { post_step }.not_to change(Site, :count)

      expect(response).to have_http_status(:ok)
    end

    context "with a step that is not in the funnel" do
      let(:step) { "teleport" }

      it "returns not found" do
        post_step

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when adding a tag name to a site" do
      subject(:post_step) { post audit_batches_path, params: { requested_step: step, audit_batch: { kind: "manual", urls: ["https://example.com"], site_tag_names: { "example.com" => ["", "Ministère"] } } } }

      it "creates nothing" do
        expect { post_step }.not_to change(Tag, :count)

        expect(response).to have_http_status(:ok)
      end
    end

    context "with a CSV file" do
      subject(:post_step) { post audit_batches_path, params: { requested_step: step, audit_batch: { kind: "csv_import", file: fixture_file_upload("sites.csv", "text/csv") } } }

      it "creates nothing" do
        expect { post_step }.not_to change(Site, :count)

        expect(response).to have_http_status(:ok)
      end
    end

    context "without a CSV file" do
      subject(:post_step) { post audit_batches_path, params: { requested_step: step, audit_batch: { kind: "csv_import" } } }

      it "stays on the file step" do
        post_step

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /audit_batches" do
    it "redirects to the first step" do
      get audit_batches_path

      expect(response).to redirect_to(new_audit_batch_path)
    end
  end

  describe "POST /audit_batches" do
    subject(:launch) { post audit_batches_path, params: { audit_batch: } }

    let(:audit_batch) do
      {
        kind: "manual",
        urls: ["https://example.com", "https://www.example.com/", "https://other.example.com"],
        site_tag_names: { "example.com" => ["", "Ministère"] }
      }
    end
    let(:sites_data) do
      [
        { "url" => "https://example.com/", "tag_names" => ["Ministère"] },
        { "url" => "https://other.example.com/", "tag_names" => [] }
      ]
    end

    it "saves the batch, enqueues the creation of its sites and audits, then returns to the audits" do
      expect { launch }.to change(AuditBatch, :count).by(1)
        .and have_enqueued_job(ProcessSiteUploadJob).with(sites_data, team.id, user.id, kind_of(Integer))

      expect(response).to redirect_to(audits_path)
      expect(flash[:notice]).to eq("2 évaluations lancées. Les résultats arriveront dans quelques minutes.")
    end

    context "with addresses and tags parsed from a CSV file" do
      let(:audit_batch) do
        {
          kind: "csv_import",
          urls: ["https://example.com/"],
          site_tag_names: { "example.com" => ["public"] }
        }
      end
      let(:sites_data) { [{ "url" => "https://example.com/", "tag_names" => ["public"] }] }

      it "enqueues the job with the site tag names" do
        expect { launch }.to have_enqueued_job(ProcessSiteUploadJob).with(sites_data, team.id, user.id, kind_of(Integer))
      end
    end

    context "with more addresses than the CSV limit supplied directly" do
      let(:audit_batch) { { kind: "csv_import", urls: } }
      let(:urls) do
        Array.new(AuditBatch::MAX_CSV_SITES + 1) do |index|
          "https://site-#{index}.example.com"
        end
      end

      it "creates nothing" do
        expect { launch }.not_to change(AuditBatch, :count)

        expect(ProcessSiteUploadJob).not_to have_been_enqueued
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with an invalid address" do
      let(:audit_batch) { { kind: "manual", urls: ["https://example.com", "not a url"] } }

      it "creates nothing" do
        expect { launch }.not_to change(AuditBatch, :count)

        expect(ProcessSiteUploadJob).not_to have_been_enqueued
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
