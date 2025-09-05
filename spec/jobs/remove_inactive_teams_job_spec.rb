require "rails_helper"

RSpec.describe RemoveInactiveTeamsJob do
  describe "#perform" do
    let!(:active_team) { create(:team) }
    let!(:inactive_team_with_users) { create(:team, updated_at: 2.years.ago) }
    let!(:inactive_team_without_users) { create(:team, updated_at: 2.years.ago) }

    before do
      create(:user, team: inactive_team_with_users)
    end

    it "destroys inactive teams without users" do
      expect { described_class.perform_now }
        .to change(Team, :count).by(-1)
        .and change { Team.exists?(inactive_team_without_users.id) }.to(false)
    end

    it "does not destroy active teams" do
      described_class.perform_now
      expect(Team.exists?(active_team.id)).to be(true)
    end

    it "does not destroy inactive teams with users" do
      described_class.perform_now
      expect(Team.exists?(inactive_team_with_users.id)).to be(true)
    end

    context "when there are no inactive teams without users" do
      let!(:inactive_team_without_users) { nil }

      it "does not destroy any teams" do
        expect { described_class.perform_now }
          .not_to change(Team, :count)
      end
    end
  end
end
