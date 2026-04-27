require "rails_helper"

RSpec.describe ProcessSiteUploadJob do
  let(:team) { create(:team) }
  let(:sites_data) do
    [
      { "url" => "https://example.com/", "name" => "Example Site", "tag_names" => ["tag1"] },
      { "url" => "https://test.com/", "name" => "Test Site", "tag_names" => ["tag2"] }
    ]
  end

  describe "#perform" do
    it "enqueues one job per site" do
      expect { described_class.perform_now(sites_data, team.id, []) }
        .to have_enqueued_job(ProcessSingleSiteJob).exactly(:twice)
    end
  end
end
