require "rails_helper"

RSpec.describe RemoveInactiveUsersJob do
  describe "#perform" do
    let!(:team) { create(:team) }
    let!(:active_user) { create(:user, siret: team.siret) }
    let!(:inactive_logged_out_user) { create(:user, siret: team.siret, updated_at: 2.years.ago) }
    let!(:inactive_logged_in_user) { create(:user, siret: team.siret, updated_at: 2.years.ago) }
    let!(:recent_logged_out_user) { create(:user, siret: team.siret, updated_at: 6.months.ago) }
    let!(:recent_logged_in_user) { create(:user, siret: team.siret) }

    before do
      if inactive_logged_in_user
        create(:session, user: inactive_logged_in_user, created_at: 2.years.ago)
        inactive_logged_in_user.update_column(:updated_at, 2.years.ago) # Force old timestamp after session creation
      end
      create(:session, user: recent_logged_in_user, created_at: 1.month.ago)
    end

    it "destroys inactive logged out users" do
      expect { described_class.perform_now }
        .to change { User.exists?(inactive_logged_out_user.id) }.to(false)
    end

    it "destroys inactive logged in users with old sessions" do
      expect { described_class.perform_now }
        .to change { User.exists?(inactive_logged_in_user.id) }.to(false)
    end

    it "does not destroy recent logged out users" do
      described_class.perform_now
      expect(User.exists?(recent_logged_out_user.id)).to be(true)
    end

    it "does not destroy recent logged in users with recent sessions" do
      described_class.perform_now
      expect(User.exists?(recent_logged_in_user.id)).to be(true)
    end

    it "does not destroy active users without sessions" do
      described_class.perform_now
      expect(User.exists?(active_user.id)).to be(true)
    end

    it "destroys all inactive users" do
      expect { described_class.perform_now }
        .to change(User, :count).by(-2)
    end

    context "when there are no inactive users" do
      let!(:inactive_logged_out_user) { nil }
      let!(:inactive_logged_in_user) { nil }

      it "does not destroy any users" do
        expect { described_class.perform_now }
          .not_to change(User, :count)
      end
    end
  end
end
