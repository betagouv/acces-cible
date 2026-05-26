require "rails_helper"

RSpec.describe SiteBatchCreationService do
  describe "#process" do
    subject(:process_site) { described_class.new(team:, tag_ids: extra_tag_ids).process(site_data) }

    let(:team) { create(:team) }
    let(:created_site) { Site.last }
    let(:site_tags) { created_site.tags.pluck(:name) }
    let(:url) { "https://example.com/" }
    let(:site_data) do
      {
        "url" => url,
        "name" => "New Name",
        "tag_names" => ["tag_1", "tag_2"]
      }
    end
    let(:extra_tag_ids) { [] }

    context "when the site does not exist" do
      it "creates a new site" do
        expect { process_site }.to change(Site, :count).by(1)
      end

      it "sets the site attributes" do
        process_site

        expect(created_site.url).to eq(url)
        expect(created_site.name).to eq("New Name")
        expect(created_site.team).to eq(team)
      end

      it "creates and associates tags" do
        process_site

        expect(site_tags).to contain_exactly("tag_1", "tag_2")
      end

      it "schedules an audit for the new site" do
        expect { process_site }.to change(Audit, :count).by(1)
      end

      context "with extra tags" do
        let(:extra_tag) { create(:tag, team:, name: "extra_tag") }
        let(:extra_tag_ids) { [extra_tag.id] }

        it "associates CSV tags and extra tags" do
          process_site

          expect(site_tags).to contain_exactly("tag_1", "tag_2", "extra_tag")
        end
      end

      context "when the CSV name is missing" do
        let(:site_data) { { "url" => url, "tag_names" => [] } }

        it "creates the site without a name" do
          process_site

          expect(created_site.name).to be_nil
        end
      end
    end

    context "when the site already exists" do
      let(:existing_tag) { create(:tag, team:, name: "existing_tag") }
      let(:site_name) { "Original Name" }
      let!(:existing_site) { create(:site, team:, url:, name: site_name, tags: [existing_tag]) }

      it "does not create a new site" do
        expect { process_site }.not_to change(Site, :count)
      end

      it "merges new tags with existing tags" do
        process_site

        expect(existing_site.reload.tags.map(&:name)).to contain_exactly("existing_tag", "tag_1", "tag_2")
      end

      it "schedules a new audit" do
        expect { process_site }.to change { existing_site.reload.audits.count }.by(1)
      end

      context "when the site name is blank" do
        let(:site_name) { "" }

        it "updates the name from the CSV" do
          expect { process_site }.to change { existing_site.reload.name }.from("").to("New Name")
        end
      end

      context "when the site name is already present" do
        it "does not overwrite the existing name" do
          expect { process_site }.not_to change { existing_site.reload.name }
        end
      end

      context "when a selected tag is already attached and present in the CSV" do
        let(:site_data) { { "url" => url, "tag_names" => ["existing_tag"] } }
        let(:extra_tag_ids) { [existing_tag.id.to_s] }

        it "does not try to attach the same tag twice" do
          process_site

          expect(existing_site.reload.tags.map(&:name)).to contain_exactly("existing_tag")
        end
      end
    end

    context "with duplicate tags" do
      let(:site_data) do
        {
          "url" => url,
          "tag_names" => ["tag", "tag"]
        }
      end
      let(:duplicate_tag) { create(:tag, team:, name: "tag") }
      let(:extra_tag_ids) { [duplicate_tag.id] }

      it "deduplicates tags" do
        process_site

        expect(site_tags).to contain_exactly("tag")
      end

      context "when selected tag IDs include a blank value from the form" do
        let(:extra_tag_ids) { [""] }

        it "ignores blank tag IDs" do
          process_site

          expect(site_tags).to contain_exactly("tag")
        end
      end
    end
  end
end
