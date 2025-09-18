require "rails_helper"

RSpec.describe User do
  subject(:user) { build(:user) }

  it { should be_valid }

  describe "validations" do
    context "for uid" do
      it { should allow_value("12345678901234").for(:uid) }
      it { should allow_value("abcdef").for(:uid) }
    end

    context "for email" do
      it { should allow_value("me@mail.com").for(:email) }
      it { should_not allow_value("not an email, even though there's an @ somewhere").for(:email) }
    end

    context "for name" do
      it { should allow_value("Yan Zhu").for(:name) }
      it { should_not allow_value("").for(:name) }
    end

    context "for siret" do
      it { should allow_value("86043616100852").for(:siret) }
      it { should_not allow_value("").for(:siret) }
    end
  end

  describe "scopes" do
    describe ".logged_in" do
      it "returns users with sessions" do
        user_with_session = create(:user)
        create(:session, user: user_with_session)
        user_without_session = create(:user)

        expect(described_class.logged_in).to include(user_with_session)
        expect(described_class.logged_in).not_to include(user_without_session)
      end
    end

    describe ".logged_out" do
      it "returns users without sessions" do
        user_with_session = create(:user)
        create(:session, user: user_with_session)
        user_without_session = create(:user)

        expect(described_class.logged_out).to include(user_without_session)
        expect(described_class.logged_out).not_to include(user_with_session)
      end
    end

    describe ".inactive" do
      it "returns users not updated in a year" do
        active_user = create(:user, updated_at: 1.minute.ago)
        inactive_user = create(:user, updated_at: described_class::MAX_IDLE_TIME.ago - 1.day)

        expect(described_class.inactive).to include(inactive_user)
        expect(described_class.inactive).not_to include(active_user)
      end
    end
  end

  describe ".from_omniauth" do
    subject(:from_omniauth) { described_class.from_omniauth(auth) }

    let(:email) { "john.doe@example.com" }
    let(:siret) { "12345678901234" }
    let(:organizational_unit) { "Engineering Department" }

    let(:auth) do
      OmniAuth::AuthHash.new(
        {
          provider: "test",
          uid: "123",
          info: {
            email:,
            organizational_unit:,
            name: "Yan Zhu"
          },
          extra: {
            raw_info: { siret: }
          }
        }
      )
    end

    context 'when in development environment' do
      let(:auth) do
        OmniAuth::AuthHash.new(
          {
            provider: "developer",
            uid: "123",
            info: {
              email:,
              organizational_unit:,
              name: "Yan Zhu",
              siret:
            }
          }
        )
      end

      context "when user does not exist" do
        it "creates a new user with the provided attributes" do
          expect { from_omniauth }.to change(described_class, :count).by(1)

          user = described_class.last
          expect(user).to have_attributes(
                            siret:,
                            provider: auth.provider,
                            uid: auth.uid,
                            email: auth.info.email,
                            name: "Yan Zhu",
                          )
        end
      end
    end

    context "when user does not exist" do
      it "creates a new user with the provided attributes" do
        expect { from_omniauth }.to change(described_class, :count).by(1)

        user = described_class.last
        expect(user).to have_attributes(
                          siret:,
                          provider: auth.provider,
                          uid: auth.uid,
                          email: auth.info.email,
                          name: "Yan Zhu",
                        )
      end

      it "creates a new team if it doesn't exist" do
        expect { from_omniauth }.to change(Team, :count).by(1)

        expect(Team.last).to have_attributes(siret:, organizational_unit:)
      end
    end

    context "when a user exists with the same email but different provider" do
      it "creates a new user" do
        user = create(:user, email: auth.info.email, provider: "other_provider", uid: auth.uid)

        expect(from_omniauth).not_to be_nil
      end
    end

    context "when user already exists" do
      let!(:existing_user) do
        create(:user, provider: auth.provider, uid: auth.uid, email: "old@example.com")
      end

      it "does not create a new user" do
        expect { from_omniauth }.not_to change(described_class, :count)
      end

      it "updates the existing user's attributes" do
        user = from_omniauth

        expect(user).to eq(existing_user.reload)
        expect(user).to have_attributes(
                          email: auth.info.email,
                          name: "Yan Zhu",
                          siret:
                        )
      end

      it "associates the user with the correct team" do
        expect(from_omniauth.team.siret).to eq(siret)
      end

      context "when reconnecting with a different siret" do
        let(:old_siret) { "98765432109876" }
        let(:new_siret) { "11111111111111" }
        let!(:old_team) { create(:team, siret: old_siret) }
        let!(:existing_user) do
          create(:user,
                 provider: auth.provider,
                 uid: auth.uid,
                 email: "old@example.com",
                 siret: old_siret,
                 team: old_team
          )
        end

        let(:auth) do
          OmniAuth::AuthHash.new(
            {
              provider: "test",
              uid: "123",
              info: {
                email:,
                organizational_unit:,
                name: "Yan Zhu"
              },
              extra: {
                raw_info: { siret: new_siret }
              }
            }
          )
        end

        it "updates the user and changes team association" do
          expect { from_omniauth }.not_to change(described_class, :count)

          user = from_omniauth
          expect(user).to eq(existing_user.reload)
          expect(user.siret).to eq(new_siret)
          expect(user.team).not_to eq(old_team)
          expect(user.team.siret).to eq(new_siret)
        end

        context "when the new team does not exist" do
          it "creates a new team and associates the user with it" do
            expect { from_omniauth }.to change(Team, :count).by(1)

            user = from_omniauth
            new_team = Team.find_by(siret: new_siret)
            expect(new_team).not_to be_nil
            expect(new_team.organizational_unit).to eq(organizational_unit)
            expect(user.team).to eq(new_team)
          end
        end
      end
    end

    context "when team already exists" do
      let!(:existing_team) { create(:team, siret:, organizational_unit: "Old Department") }

      it "does not create a new team" do
        expect { from_omniauth }.not_to change(Team, :count)
      end

      it "updates the existing team's organizational_unit" do
        expect { from_omniauth }.to change { existing_team.reload.organizational_unit }
      end
    end

    context "when user update fails" do
      before do
        allow_any_instance_of(described_class).to receive(:save).and_return(false) # rubocop:disable RSpec/AnyInstance
      end

      it "returns nil" do
        expect(from_omniauth).to be_nil
      end

      it "does not create a team" do
        expect { from_omniauth }.not_to change(Team, :count)
      end
    end

    context "with invalid data" do
      let(:email) { "invalid-email" }

      it "returns nil" do
        expect(from_omniauth).to be_nil
      end
    end
  end
end
