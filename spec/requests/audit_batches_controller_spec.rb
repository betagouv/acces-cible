require "rails_helper"

RSpec.describe "AuditBatches" do
  let!(:user) { create(:user) }

  before { login_as(user) }

  describe "GET /audit_batches/new" do
    subject(:get_new) { get new_audit_batch_path }

    it "offers the manual method and disables the csv import" do
      get_new

      html = Nokogiri::HTML(response.body)

      expect(html.at_css("input[value=manual]")[:disabled]).to be_nil
      expect(html.at_css("input[value=csv_import]")[:disabled]).to be_present
    end

    it "sends the back button to the site list on the first step" do
      get_new

      back = Nokogiri::HTML(response.body).at_css("main a.fr-btn--secondary")

      expect(back.text).to eq(I18n.t("shared.back"))
      expect(back["href"]).to eq(sites_path)
    end
  end

  describe "POST /audit_batches" do
    subject(:post_create) { post audit_batches_path, params: { audit_batch: { kind: } } }

    context "with the manual method" do
      let(:kind) { "manual" }
      let(:batch) { AuditBatch.last }

      it "creates a draft batch and moves to the addresses" do
        expect { post_create }.to change(AuditBatch, :count).by(1)

        expect(batch).to be_draft
        expect(batch.user).to eq(user)
        expect(response).to redirect_to(step_audit_batch_path(batch, "urls"))
      end
    end

    context "with the csv import, which is not available yet" do
      let(:kind) { "csv_import" }

      it "is rejected without creating anything" do
        expect { post_create }.not_to change(AuditBatch, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with a kind that does not exist" do
      let(:kind) { "telepathy" }

      it "is rejected without creating anything" do
        expect { post_create }.not_to change(AuditBatch, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /audit_batches/:id/steps/:step" do
    let(:audit_batch) { create(:audit_batch, user:) }

    it "sends a step that is out of reach back to the first incomplete one" do
      get step_audit_batch_path(audit_batch, "summary")

      expect(response).to redirect_to(step_audit_batch_path(audit_batch, "urls"))
    end

    it "does not know a step that is not in the funnel" do
      get step_audit_batch_path(audit_batch, "payment")

      expect(response).to have_http_status(:not_found)
    end

    it "does not expose a batch belonging to someone else on the team" do
      other = create(:audit_batch, user: create(:user, team: user.team))

      get step_audit_batch_path(other, "urls")

      expect(response).to have_http_status(:not_found)
    end

    it "does not expose a batch that has already been launched" do
      launched = create(:audit_batch, :launched, user:)

      get step_audit_batch_path(launched, "urls")

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /audit_batches/:id/steps/method" do
    let(:audit_batch) { create(:audit_batch, user:) }

    it "moves on to the addresses" do
      patch step_audit_batch_path(audit_batch, "method"), params: { audit_batch: { kind: "manual" } }

      expect(response).to redirect_to(step_audit_batch_path(audit_batch, "urls"))
    end
  end

  describe "DELETE /audit_batches/:id" do
    let!(:audit_batch) { create(:audit_batch, user:) }

    it "abandons the batch and returns to the site list" do
      expect { delete audit_batch_path(audit_batch) }.to change(AuditBatch, :count).by(-1)

      expect(response).to redirect_to(sites_path)
    end
  end
end
