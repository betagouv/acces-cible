require "rails_helper"

RSpec.describe ProcessSingleSiteJob do
  describe "#perform" do
    subject(:run_process_single_site_job) { described_class.new.perform(site_data, team.id, extra_tag_ids) }

    let(:team) { create(:team) }
    let(:site_data) do
      {
        "url" => "https://example.com/",
        "name" => "New Name",
        "tag_names" => ["tag_1", "tag_2"]
      }
    end
    let(:extra_tag_ids) { [] }

    context "when the site does not exist" do
      it "creates a new site" do
        expect { run_process_single_site_job }.to change(Site, :count).by(1)
      end

      it "sets the correct attributes" do
        run_process_single_site_job

        site = Site.last
        expect(site.url).to eq("https://example.com/")
        expect(site.name).to eq("New Name")
        expect(site.team).to eq(team)
      end

      it "creates and associates the tags" do
        run_process_single_site_job

        site = Site.last
        expect(site.tags.map(&:name)).to contain_exactly("tag_1", "tag_2")
      end

      context "with extra tags provided" do
        let(:extra_tag) { create(:tag, team: team, name: "extra_tag") }
        let(:extra_tag_ids) { [extra_tag.id] }

        it "associates both CSV tags and extra tags" do
          run_process_single_site_job

          expect(Site.last.tags.map(&:name)).to contain_exactly("tag_1", "tag_2", "extra_tag")
        end
      end

      context "when the name is missing in the CSV" do
        let(:site_data) { { "url" => "https://example.com/", "tag_names" => [] } }

        it "creates the site without a name" do
          run_process_single_site_job

          expect(Site.last.name).to be_nil
        end
      end
    end

    context "when the site already exists" do
      let!(:site) { create(:site, team: team, url: "https://example.com/", name: "Original Name") }
      let!(:existing_tag) { create(:tag, team: team, name: "existing_tag") }

      before do
        site.tags << existing_tag
      end

      it "does not create a new site" do
        expect { run_process_single_site_job }.not_to change(Site, :count)
      end

      it "creates only new tags" do
        expect { run_process_single_site_job }.to change(Tag, :count).by(2)
      end

      it "merges the new tags with the existing ones" do
        run_process_single_site_job

        expect(site.reload.tags.map(&:name)).to contain_exactly("existing_tag", "tag_1", "tag_2")
      end

      context "when the site name is blank" do
        before { site.update!(name: nil) }

        it "updates the name from the CSV" do
          expect { run_process_single_site_job }.to change { site.reload.name }.from(nil).to("New Name")
        end
      end

      context "when the site name is already present" do
        it "does not overwrite the existing name" do
          expect { run_process_single_site_job }.not_to change { site.reload.name }
        end
      end
    end

    context "with duplicate tags" do
      let(:site_data) do
        {
          "url" => "https://example.com/",
          "tag_names" => ["tag", "tag"]
        }
      end
      let(:duplicate_tag) { create(:tag, team: team, name: "tag") }
      let(:extra_tag_ids) { [duplicate_tag.id] }

      it "deduplicates the tags" do
        run_process_single_site_job

        expect(Site.last.tags.map(&:name)).to contain_exactly("tag")
      end
    end
  end
end
