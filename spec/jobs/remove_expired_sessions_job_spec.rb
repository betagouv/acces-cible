require "rails_helper"

RSpec.describe RemoveExpiredSessionsJob do
  describe "#perform" do
    let!(:user) { create(:user) }
    let!(:active_session) { create(:session, user:, updated_at: 1.minute.ago) }

    context "with a session idle for too long" do
      before { create(:session, user:, updated_at: Session::MAX_IDLE_TIME.ago - 1.day) }

      it "destroys the idle session and keeps the active one" do
        expect { described_class.perform_now }.to change(Session, :count).by(-1)
        expect(Session.all).to contain_exactly(active_session)
      end

      it "does not update the user" do
        expect { described_class.perform_now }.not_to change { user.reload.updated_at }
      end
    end

    context "with a session older than the maximum lifetime" do
      before { create(:session, user:, created_at: Session::MAX_LIFETIME.ago - 1.day, updated_at: 1.minute.ago) }

      it "destroys the too old session even though the user stayed active" do
        expect { described_class.perform_now }.to change(Session, :count).by(-1)
        expect(Session.all).to contain_exactly(active_session)
      end

      it "does not update the user" do
        expect { described_class.perform_now }.not_to change { user.reload.updated_at }
      end
    end
  end
end
