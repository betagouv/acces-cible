require "rails_helper"

RSpec.describe Session do
  subject(:session) { build(:session) }

  it { is_expected.to be_valid }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "scopes" do
    let(:active_session) { create(:session, updated_at: 1.minute.ago) }
    let(:idle_session) { create(:session, updated_at: described_class::MAX_IDLE_TIME.ago - 1.day) }
    let(:too_old_session) { create(:session, created_at: described_class::MAX_LIFETIME.ago - 1.day, updated_at: 1.minute.ago) }

    describe ".active" do
      it "returns sessions updated within the max idle time" do
        expect(described_class.active).to include(active_session)
        expect(described_class.active).not_to include(idle_session)
      end

      it "excludes sessions created before the max lifetime, even when still used" do
        expect(described_class.active).not_to include(too_old_session)
      end
    end

    describe ".expired" do
      it "returns sessions not updated within the max idle time" do
        expect(described_class.expired).to include(idle_session)
        expect(described_class.expired).not_to include(active_session)
      end

      it "returns sessions created before the max lifetime, even when still used" do
        expect(described_class.expired).to include(too_old_session)
      end
    end
  end

  describe "#should_touch?" do
    context "when session was updated more than 1 day ago" do
      it "returns true" do
        session = build(:session, updated_at: 2.days.ago)

        expect(session.should_touch?).to be true
      end
    end

    context "when session was updated less than 1 day ago" do
      it "returns false" do
        session = build(:session, updated_at: 1.hour.ago)

        expect(session.should_touch?).to be false
      end
    end
  end
end
