require "rails_helper"

RSpec.describe Session do
  subject(:session) { build(:session) }

  it { should be_valid }

  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "scopes" do
    describe ".active" do
      it "returns sessions updated within the max idle time" do
        active_session = create(:session, updated_at: 1.minute.ago)
        inactive_session = create(:session, updated_at: described_class::MAX_IDLE_TIME.ago - 1.day)

        expect(described_class.active).to include(active_session)
        expect(described_class.active).not_to include(inactive_session)
      end
    end

    describe ".inactive" do
      it "returns sessions not updated within the max idle time" do
        active_session = create(:session, updated_at: 1.minute.ago)
        inactive_session = create(:session, updated_at: described_class::MAX_IDLE_TIME.ago - 1.day)

        expect(described_class.inactive).to include(inactive_session)
        expect(described_class.inactive).not_to include(active_session)
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
