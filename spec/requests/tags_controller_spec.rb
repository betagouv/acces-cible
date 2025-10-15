require "rails_helper"

RSpec.describe "Tags" do
  let!(:user) { create(:user) }
  let(:team) { user.team }

  before { login_as(user) }

  describe "GET /tags" do
    subject(:get_tags) { get tags_path }

    it "returns success and lists tags in alphabetical order" do
      zebra = create(:tag, name: "zebra", team:)
      alpha = create(:tag, name: "alpha", team:)

      get_tags

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_link(alpha.name, href: tag_path(alpha))
      expect(response.body).to have_link(zebra.name, href: tag_path(zebra))
      alpha_position = response.body.index(alpha.name)
      zebra_position = response.body.index(zebra.name)
      expect(alpha_position).to be < zebra_position
    end

    it "only shows tags for the current user's team" do
      other_tag = create(:tag, name: "Other team tag", team: create(:team))
      own_tag = create(:tag, name: "My team tag", team:)

      get_tags

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_link(own_tag.name, href: tag_path(own_tag))
      expect(response.body).not_to have_link(other_tag.name, href: tag_path(other_tag))
    end
  end

  describe "POST /tags" do
    subject(:create_tag) { post tags_path, params: }

    let(:turbo_stream) { "text/vnd.turbo-stream.html" }

    context "when creating a tag from Site form" do
      let(:params) { { site: { tags_attributes: { name: "new tag" }, tag_ids: existing_tag_ids } } }
      let(:existing_tag_ids) { [] }
      let(:frame_id) { "tags_site" }

      it "creates a new tag and returns turbo stream" do
        expect { create_tag }.to change(Tag, :count).by(1)

        tag = Tag.last
        expect(tag.name).to eq("new tag")
        expect(tag.team).to eq(team)
        expect(response.media_type).to eq(turbo_stream)
        expect(response.body).to have_css("turbo-stream[action='replace'][target='#{frame_id}']")
      end

      it "finds existing tag instead of creating duplicate" do
        existing_tag = create(:tag, name: "existing tag", team:)

        expect do
          post tags_path, params: { site: { tags_attributes: { name: "existing tag" }, tag_ids: [] } }
        end.not_to change(Tag, :count)

        expect(response.media_type).to eq(turbo_stream)
      end

      context "when name is blank" do
        let(:params) { { site: { tags_attributes: { name: "" }, tag_ids: [] } } }

        it "returns unprocessable_content status" do
          expect { create_tag }.not_to change(Tag, :count)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when including existing tag_ids" do
        let(:existing_tag) { create(:tag, team:) }
        let(:existing_tag_ids) { [existing_tag.id] }

        it "combines new tag with existing tag_ids" do
          create_tag

          expect(response.media_type).to eq(turbo_stream)
          new_tag = Tag.last
          expect(response.body).to include(existing_tag.name) # We can't use have_css here because
          expect(response.body).to include(new_tag.name)      # Capybara matchers ignore <template> tags
        end
      end
    end

    context "when creating a tag from SiteUpload form" do
      let(:params) { { site_upload: { tags_attributes: { name: "upload tag" }, tag_ids: [] } } }
      let(:frame_id) { "tags_site_upload" }

      it "creates a new tag for upload context" do
        expect { create_tag }.to change(Tag, :count).by(1)

        tag = Tag.last
        expect(tag.name).to eq("upload tag")
        expect(response.media_type).to eq(turbo_stream)
        expect(response.body).to have_css("turbo-stream[action='replace'][target='#{frame_id}']")
      end
    end
  end

  describe "GET /tags/:id" do
    subject(:get_tag) { get tag_path(tag) }

    let(:tag) { create(:tag, team:) }

    it "returns success and shows the tag" do
      get_tag

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_css("h1", text: tag.name)
    end

    it "paginates sites associated with the tag" do
      site1 = create(:site, team:)
      site2 = create(:site, team:)
      tag.sites << [site1, site2]

      get_tag

      expect(response).to have_http_status(:ok)
      expect(tag.sites.count).to eq(2)
    end

    context "when accessing with old slug" do
      it "redirects to current slug with moved_permanently status" do
        old_slug = tag.slug
        tag.update!(name: "new name")

        get "/tags/#{old_slug}"

        expect(response).to redirect_to(tag_path(tag))
        expect(response).to have_http_status(:moved_permanently)
      end
    end

    context "when tag belongs to another team" do
      let(:other_team) { create(:team) }
      let(:tag) { create(:tag, team: other_team) }

      it "returns not found status" do
        get_tag

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /tags/:id/edit" do
    subject(:edit_tag) { get edit_tag_path(tag) }

    let(:tag) { create(:tag, team:) }

    it "returns success and renders edit form" do
      edit_tag

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_css("form")
      expect(response.body).to have_field("tag[name]", with: tag.name)
    end

    context "when accessing with old slug" do
      it "redirects to current slug with moved_permanently status" do
        old_slug = tag.slug
        tag.update!(name: "new name")

        get "/tags/#{old_slug}/edit"

        expect(response).to redirect_to(tag_path(tag))
        expect(response).to have_http_status(:moved_permanently)
      end
    end
  end

  describe "PATCH /tags/:id" do
    subject(:update_tag) { patch tag_path(tag), params: { tag: { name: new_name } } }

    let(:tag) { create(:tag, team:) }
    let(:new_name) { "updated tag name" }

    it "updates the tag and redirects to show page" do
      update_tag

      expect(tag.reload.name).to eq(new_name)
      expect(response).to redirect_to(tag_path(tag))
      expect(response).to have_http_status(:see_other)
      follow_redirect!
      expect(flash[:notice]).to be_present
      expect(response.body).to have_css("h1", text: new_name)
    end

    context "when update is invalid" do
      let(:new_name) { "" }

      it "renders edit form with unprocessable_content status" do
        original_name = tag.name

        update_tag

        expect(response).to have_http_status(:unprocessable_content)
        expect(tag.reload.name).to eq(original_name)
        expect(response.body).to have_css("form")
        expect(response.body).to have_field("tag[name]")
      end
    end

    context "when tag belongs to another team" do
      let(:other_team) { create(:team) }
      let(:tag) { create(:tag, team: other_team) }

      it "returns not found status" do
        update_tag

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /tags/:id" do
    subject(:delete_tag) { delete tag_path(tag) }

    let!(:tag) { create(:tag, team:) }

    it "destroys the tag and redirects to index" do
      expect { delete_tag }.to change(Tag, :count).by(-1)

      expect(response).to redirect_to(tags_path)
      expect(response).to have_http_status(:see_other)
      follow_redirect!
      expect(flash[:notice]).to be_present
    end

    context "when tag has associated sites" do
      before do
        site = create(:site, team:)
        tag.sites << site
      end

      it "destroys the tag and its associations" do
        expect { delete_tag }.to change(Tag, :count).by(-1)
          .and change(SiteTag, :count).by(-1)

        expect(response).to redirect_to(tags_path)
      end
    end

    context "when tag belongs to another team" do
      let(:other_team) { create(:team) }
      let(:tag) { create(:tag, team: other_team) }

      it "returns not found status" do
        delete_tag

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
