require "rails_helper"

RSpec.describe RemoveObsoleteSessionsJob do
  describe "#perform" do
    let!(:user) { create(:user) }
    let!(:active_session) { create(:session, user:, updated_at: 1.week.ago) }
    let!(:obsolete_session) { create(:session, user:, updated_at: 2.months.ago) }

    it "destroys sessions older than SESSION_DURATION" do
      expect { described_class.perform_now }
        .to change { Session.exists?(obsolete_session.id) }.to(false)
    end

    it "does not destroy recent sessions" do
      described_class.perform_now
      expect(Session.exists?(active_session.id)).to be(true)
    end

    it "does not update users when removing obsolete sessions" do
      user_updated_at = user.updated_at

      expect { described_class.perform_now }
        .not_to change { user.reload.updated_at }
    end

    it "destroys all obsolete sessions" do
      create(:session, user:, updated_at: 3.months.ago)

      expect { described_class.perform_now }
        .to change(Session, :count).by(-2)
    end

    context "when there are no obsolete sessions" do
      let!(:obsolete_session) { nil }

      it "does not destroy any sessions" do
        expect { described_class.perform_now }
          .not_to change(Session, :count)
      end
    end
  end
end
