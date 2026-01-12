require "rails_helper"

RSpec.describe ProcessSiteUploadJob do
  subject(:job) { described_class.new }

  let(:team) { create(:team) }
  let(:sites_data) do
    [
      { "url" => "https://example.com/", "name" => "Example Site", "tag_names" => ["tag1"] },
      { "url" => "https://test.com/", "name" => "Test Site", "tag_names" => ["tag2"] }
    ]
  end
  let(:tag_ids) { [] }

  describe "#perform" do
    it "creates ProcessSingleSiteJob for each site" do
      expect { job.perform(sites_data, team.id, tag_ids) }
        .to have_enqueued_job(ProcessSingleSiteJob).exactly(:twice)
    end
  end
end
