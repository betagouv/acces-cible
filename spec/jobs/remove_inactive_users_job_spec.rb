require "rails_helper"

RSpec.describe RemoveInactiveUsersJob do
  describe "#perform" do
    let!(:team) { create(:team) }
    let!(:active_user) { create(:user, team:) }
    let!(:inactive_user) { create(:user, team:, updated_at: User::MAX_IDLE_TIME.ago - 1.day) }

    it "destroys inactive users" do
      expect { described_class.perform_now }.to change(User, :count).by(-1)
      expect(User.all).to contain_exactly(active_user)
    end

    context "when there are no inactive users" do
      it "does not destroy any users" do
        User.update_all(updated_at: 1.minute.ago)

        expect { described_class.perform_now }.not_to change(User, :count)
      end
    end
  end
end
