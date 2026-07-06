require "rails_helper"

RSpec.describe ProcessBatchSitesCreationJob do
  describe "#perform" do
    subject(:run_job) { described_class.new.perform(sites_data, team.id, extra_tag_ids, user.id) }

    let(:user) { create(:user) }
    let(:team) { create(:team, users: [user]) }
    let(:url) { "https://example.com/" }
    let(:sites_data) do
      [
        { "url" => url, "name" => "Example", "tag_names" => ["tag_1"] },
        { "url" => "https://test.com/", "name" => "Test", "tag_names" => ["tag_2"] }
      ]
    end
    let(:extra_tag_ids) { [] }

    it "processes all sites in the batch" do
      expect { run_job }.to change(Site, :count).by(2)
    end

    it "broadcasts a sites index refresh after the batch" do
      allow(Turbo::StreamsChannel).to receive(:broadcast_refresh_later_to)

      run_job

      expect(Turbo::StreamsChannel).to have_received(:broadcast_refresh_later_to).with([team, :sites])
    end
  end
end
