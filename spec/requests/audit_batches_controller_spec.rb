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

      expect(response.body).to have_link(I18n.t("shared.back"), href: sites_path)
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

    it "recaps the deduplicated addresses" do
      audit_batch.update!(urls: ["https://example.com", "https://www.example.com/"])

      get step_audit_batch_path(audit_batch, "summary")

      expect(response.body).to include(I18n.t("audit_batches.steps.summary.intro_html", count: 1))
    end

    it "gives each site its own tag fields" do
      create(:tag, team: user.team)
      audit_batch.update!(urls: ["https://example.com"])

      get step_audit_batch_path(audit_batch, "summary")

      expect(response.body).to have_css("input[name='audit_batch[site_tags][#{audit_batch.sites.first.id}][tag_ids][]']")
    end

    it "shows the automatic tests as always on and out of reach" do
      audit_batch.update!(urls: ["https://example.com"])

      get step_audit_batch_path(audit_batch, "checks")

      expect(response.body).to have_field(I18n.t("audit_batches.steps.checks.toggle"), checked: true, disabled: true)
      expect(response.body).to include(I18n.t("audit_batches.steps.checks.hint"))
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

  describe "PATCH /audit_batches/:id/steps/urls" do
    subject(:submit_urls) { patch step_audit_batch_path(audit_batch, "urls"), params: { audit_batch: { urls: } } }

    let(:audit_batch) { create(:audit_batch, user:) }

    context "with valid addresses" do
      let(:urls) { ["https://example.com", "https://www.example.com/", "https://other.fr"] }

      it "creates one audit per deduplicated address and moves on" do
        expect { submit_urls }.to change(audit_batch.audits, :count).by(2)

        expect(response).to redirect_to(step_audit_batch_path(audit_batch, "summary"))
      end
    end

    context "with only blank addresses" do
      let(:urls) { ["", "  "] }

      it "asks for at least one address without creating anything" do
        expect { submit_urls }.not_to change(Site, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t("activerecord.errors.models.audit_batch.attributes.urls.too_short"))
      end
    end

    context "with more addresses than allowed" do
      let(:urls) { Array.new(AuditBatch::MAX_SITES + 1) { |index| "https://site-#{index}.fr" } }

      it "is rejected without creating anything" do
        expect { submit_urls }.not_to change(Site, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with an invalid address" do
      let(:urls) { ["https://example.com", "not a url"] }
      let(:message) { Site.new(url: "not a url").tap(&:validate).errors.full_messages_for(:url).first }

      it "reports the error on its own field without losing the other address" do
        expect { submit_urls }.not_to change(Site, :count)

        rows = Nokogiri::HTML(response.body).css("form ol li")

        expect(rows.css("input").map { it[:value] }).to eq(["https://example.com/", "not a url"])
        expect(rows.map { it.text.include?(message) }).to eq([false, true])
      end
    end
  end

  describe "PATCH /audit_batches/:id/steps/summary" do
    subject(:submit_summary) { patch step_audit_batch_path(audit_batch, "summary"), params: { audit_batch: { site_tags: } } }

    let(:audit_batch) { create(:audit_batch, user:).tap { it.update!(urls: ["https://example.com"]) } }
    let(:site) { audit_batch.sites.first }

    context "with a tag of the team" do
      let(:tag) { create(:tag, team: user.team) }
      let(:site_tags) { { site.id => { tag_ids: [tag.id] } } }

      it "tags the site and moves on to the checks" do
        expect { submit_summary }.to change { site.tags.reload.to_a }.from([]).to([tag])

        expect(response).to redirect_to(step_audit_batch_path(audit_batch, "checks"))
      end
    end

    context "with a tag that is being created" do
      let(:site_tags) { { site.id => { tags_attributes: { name: "Ministère" } } } }

      it "creates it for the team and tags the site with it" do
        expect { submit_summary }.to change(Tag, :count).by(1)

        expect(site.tags.reload.map(&:name)).to eq(["Ministère"])
      end
    end

    context "with a tag belonging to another team" do
      let(:site_tags) { { site.id => { tag_ids: [create(:tag, team: create(:team)).id] } } }

      it "does not tag the site with it" do
        submit_summary

        expect(site.tags.reload).to be_empty
      end
    end
  end

  describe "PATCH /audit_batches/:id/steps/checks" do
    subject(:launch) { patch step_audit_batch_path(audit_batch, "checks") }

    let(:audit_batch) { create(:audit_batch, user:).tap { it.update!(urls: ["https://example.com"]) } }

    it "launches the batch and its audits, then returns to the site list" do
      expect { launch }.to change { audit_batch.reload.status }.from("draft").to("launched")

      expect(audit_batch.audits).to all(be_launched)
      expect(response).to redirect_to(sites_path)
    end

    it "sends a batch without addresses back to them, without launching it" do
      empty = create(:audit_batch, user:)

      patch step_audit_batch_path(empty, "checks")

      expect(empty.reload).to be_draft
      expect(response).to redirect_to(step_audit_batch_path(empty, "urls"))
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
