require "rails_helper"

RSpec.describe ProcessSingleSiteJob do
  subject(:job) { described_class.new }

  let(:team) { create(:team) }
  let(:site_data) { { "url" => "https://example.com/", "name" => "Example Site", "tag_names" => ["tag1", "tag2"] } }
  let(:tag_ids) { [] }

  describe "#perform" do
    context "when site does not exist" do
      it "creates a new site with tags" do
        expect {
          job.perform(site_data, team.id, tag_ids)
        }.to change(Site, :count).by(1)

        site = Site.last
        expect(site.url).to eq("https://example.com/")
        expect(site.name).to eq("Example Site")
        expect(site.tags.pluck(:name)).to match_array(["tag1", "tag2"])
      end

      it "creates tags if they don't exist" do
        expect {
          job.perform(site_data, team.id, tag_ids)
        }.to change(Tag, :count).by(2)
      end

      context "with form tag_ids" do
        let!(:form_tag) { create(:tag, name: "form_tag", team: team) }
        let(:tag_ids) { [form_tag.id] }

        it "combines CSV tags with form tags" do
          job.perform(site_data, team.id, tag_ids)

          site = Site.last
          expect(site.tags.pluck(:name)).to match_array(["tag1", "tag2", "form_tag"])
        end
      end

      context "without name in CSV" do
        let(:site_data) { { "url" => "https://example.com/", "name" => nil, "tag_names" => [] } }

        it "creates site without name" do
          job.perform(site_data, team.id, tag_ids)

          site = Site.last
          expect(site.name).to be_nil
        end
      end
    end

    context "when site already exists" do
      let!(:existing_site) { create(:site, url: "https://example.com/", name: nil, team: team) }
      let!(:existing_tag) { create(:tag, name: "existing_tag", team: team) }

      before do
        existing_site.tags << existing_tag
      end

      it "does not create a new site" do
        expect {
          job.perform(site_data, team.id, tag_ids)
        }.not_to change(Site, :count)
      end

      it "merges tags with existing tags" do
        job.perform(site_data, team.id, tag_ids)

        existing_site.reload
        expect(existing_site.tags.pluck(:name)).to match_array(["existing_tag", "tag1", "tag2"])
      end

      it "sets name if site has no name" do
        job.perform(site_data, team.id, tag_ids)

        existing_site.reload
        expect(existing_site.name).to eq("Example Site")
      end

      it "does not overwrite existing name" do
        existing_site.update!(name: "Old Name")

        job.perform(site_data, team.id, tag_ids)

        existing_site.reload
        expect(existing_site.name).to eq("Old Name")
      end

      it "triggers audit on existing site" do
        expect(existing_site).to receive(:audit!)

        job.perform(site_data, team.id, tag_ids)
      end

      context "with form tag_ids" do
        let!(:form_tag) { create(:tag, name: "form_tag", team: team) }
        let(:tag_ids) { [form_tag.id] }

        it "combines all tags" do
          job.perform(site_data, team.id, tag_ids)

          existing_site.reload
          expect(existing_site.tags.pluck(:name)).to match_array(["existing_tag", "tag1", "tag2", "form_tag"])
        end
      end
    end

    context "with duplicate tags in CSV" do
      let(:site_data) { { "url" => "https://example.com/", "name" => "Example Site", "tag_names" => ["tag1", "tag1", "tag2"] } }

      it "deduplicates tags" do
        expect {
          job.perform(site_data, team.id, tag_ids)
        }.to change(Tag, :count).by(1)

        site = Site.last
        expect(site.tags.pluck(:name)).to match_array(["tag1", "tag2"])
      end
    end

    context "with existing tags" do
      let!(:existing_tag) { create(:tag, name: "tag1", team: team) }

      it "reuses existing tags instead of creating new ones" do
        expect {
          job.perform(site_data, team.id, tag_ids)
        }.to change(Tag, :count).by(1)

        site = Site.last
        expect(site.tags).to include(existing_tag)
      end
    end
  end
end
