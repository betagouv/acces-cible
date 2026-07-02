require "rails_helper"

RSpec.describe ProcessSiteUploadJob do
  let(:team) { create(:team) }
  let(:user) { create(:user) }
  let(:sites_data) do
    [
      { "url" => "https://example.com/", "name" => "Example Site", "tag_names" => ["tag1"] },
      { "url" => "https://test.com/", "name" => "Test Site", "tag_names" => ["tag2"] }
    ]
  end

  describe "#perform" do
    it "enqueues one job for the batch" do
      expect { described_class.perform_now(sites_data, team.id, [], user.id) }
        .to have_enqueued_job(ProcessBatchSitesCreationJob).with(sites_data, team.id, [], user.id).exactly(:once)
    end

    it "splits large imports into batches of 100 sites" do
      sites_data = Array.new(201) do |index|
        { "url" => "https://example-#{index}.com/", "name" => "Example #{index}", "tag_names" => [] }
      end

      expect { described_class.perform_now(sites_data, team.id, [], user.id) }
        .to have_enqueued_job(ProcessBatchSitesCreationJob).exactly(3).times
    end
  end
end
