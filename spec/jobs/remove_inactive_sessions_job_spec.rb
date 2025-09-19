require "rails_helper"

RSpec.describe RemoveInactiveSessionsJob do
  describe "#perform" do
    let!(:user) { create(:user) }
    let!(:active_session) { create(:session, user:, updated_at: 1.minute.ago) }
    let!(:inactive_session) { create(:session, user:, updated_at: Session::MAX_IDLE_TIME.ago - 1.day) }

    it "destroys inactive sessions" do
      expect { described_class.perform_now }.to change(Session, :count).by(-1)
      expect(Session.all).to contain_exactly(active_session)
    end

    it "does not update users when removing their inactive sessions" do
      expect { described_class.perform_now }.not_to change { user.reload.updated_at }
    end

    context "when there are no inactive sessions" do
      it "does nothing" do
        Session.inactive.delete_all

        expect { described_class.perform_now }.not_to change(Session, :count)
      end
    end
  end
end
