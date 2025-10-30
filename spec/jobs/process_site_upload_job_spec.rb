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
      expect(ProcessSingleSiteJob).to receive(:new).with(sites_data[0], team.id, tag_ids).and_call_original
      expect(ProcessSingleSiteJob).to receive(:new).with(sites_data[1], team.id, tag_ids).and_call_original

      job.perform(sites_data, team.id, tag_ids)
    end

    it "enqueues all site jobs" do
      expect(ActiveJob).to receive(:perform_all_later) do |jobs|
        expect(jobs.length).to eq(2)
        expect(jobs).to all(be_a(ProcessSingleSiteJob))
      end

      job.perform(sites_data, team.id, tag_ids)
    end

    context "with empty sites_data" do
      let(:sites_data) { [] }

      it "does not enqueue any jobs" do
        expect(ActiveJob).not_to receive(:perform_all_later)

        job.perform(sites_data, team.id, tag_ids)
      end
    end

    context "with single site" do
      let(:sites_data) do
        [{ "url" => "https://example.com/", "name" => "Example Site", "tag_names" => [] }]
      end

      it "enqueues one job" do
        expect(ActiveJob).to receive(:perform_all_later) do |jobs|
          expect(jobs.length).to eq(1)
        end

        job.perform(sites_data, team.id, tag_ids)
      end
    end

    context "with tag_ids" do
      let(:tag_ids) { [1, 2, 3] }

      it "passes tag_ids to each ProcessSingleSiteJob" do
        expect(ProcessSingleSiteJob).to receive(:new).with(sites_data[0], team.id, [1, 2, 3]).and_call_original
        expect(ProcessSingleSiteJob).to receive(:new).with(sites_data[1], team.id, [1, 2, 3]).and_call_original

        job.perform(sites_data, team.id, tag_ids)
      end
    end
  end
end
