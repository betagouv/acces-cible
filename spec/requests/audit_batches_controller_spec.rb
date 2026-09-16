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
  end

  describe "POST /audit_batches" do
    subject(:launch) { post audit_batches_path, params: { audit_batch: } }

    let(:audit_batch) do
      {
        kind: "manual",
        urls: ["https://example.com", "https://www.example.com/", "https://other.example.com"],
        site_tags: { "example.com" => { tag_ids: ["", "1"], tags_attributes: { name: "Ministère" } } }
      }
    end
    let(:sites_data) do
      [
        { "url" => "https://example.com/", "tag_ids" => ["", "1"], "tag_names" => ["Ministère"] },
        { "url" => "https://other.example.com/", "tag_ids" => nil, "tag_names" => [] }
      ]
    end

    it "saves the batch, enqueues the creation of its sites and audits, then returns to the audits" do
      expect { launch }.to change(AuditBatch, :count).by(1)
        .and have_enqueued_job(ProcessAuditBatchCreationJob).with(sites_data, team.id, [], user.id, kind_of(Integer))

      expect(response).to redirect_to(audits_path)
      expect(flash[:notice]).to eq("2 évaluations lancées. Les résultats arriveront dans quelques minutes.")
    end

    context "with an invalid address" do
      let(:audit_batch) { { kind: "manual", urls: ["https://example.com", "not a url"] } }

      it "creates nothing" do
        expect { launch }.not_to change(AuditBatch, :count)

        expect(ProcessAuditBatchCreationJob).not_to have_been_enqueued
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
