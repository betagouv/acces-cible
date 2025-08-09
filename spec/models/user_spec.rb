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

    context "for names" do
      it { should allow_value("Yan").for(:given_name) }
      it { should allow_value("Zhu").for(:usual_name) }
      it { should allow_value(nil).for(:given_name) }
      it { should allow_value(nil).for(:usual_name) }

      it "requires at least one name to be present" do
        user.given_name = nil
        user.usual_name = nil
        expect(user).not_to be_valid
        expect(user.errors[:given_name]).to include("Veuillez indiquer au moins un prénom ou un nom.")
      end

      it "is valid with only given_name" do
        user.given_name = "Yan"
        user.usual_name = nil
        expect(user).to be_valid
      end

      it "is valid with only usual_name" do
        user.given_name = nil
        user.usual_name = "Zhu"
        expect(user).to be_valid
      end

      it "is valid with both names" do
        user.given_name = "Yan"
        user.usual_name = "Zhu"
        expect(user).to be_valid
      end
    end

    context "for siret" do
      it { should allow_value("86043616100852").for(:siret) }
      it { should_not allow_value("").for(:siret) }
    end
  end

  describe ".from_omniauth" do
    subject(:from_omniauth) { described_class.from_omniauth(auth) }

    let(:email) { "yan.zhu@example.com" }
    let(:siret) { "12345678901234" }
    let(:organizational_unit) { "Engineering Department" }

    let(:auth) do
      OmniAuth::AuthHash.new(
        {
          provider: "test",
          uid: "123",
          info: { email: },
          extra: {
            raw_info: {
              email:,
              siret:,
              organizational_unit:,
              given_name: "Yan",
              usual_name: "Zhu"
            }
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
                          given_name: auth.extra.raw_info.given_name,
                          usual_name: auth.extra.raw_info.usual_name,
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
                          given_name: auth.extra.raw_info.given_name,
                          usual_name: auth.extra.raw_info.usual_name,
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
              info: { email: },
              extra: {
                raw_info: {
                  email:,
                  siret: new_siret,
                  organizational_unit:,
                  given_name: "John",
                  usual_name: "Doe"
                }
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

  describe "#full_name" do
    it "returns both names when both are present" do
      user.given_name = "Yan"
      user.usual_name = "Zhu"
      expect(user.full_name).to eq("Yan Zhu")
    end

    it "returns only given_name when usual_name is nil" do
      user.given_name = "Yan"
      user.usual_name = nil
      expect(user.full_name).to eq("Yan")
    end

    it "returns only usual_name when given_name is nil" do
      user.given_name = nil
      user.usual_name = "Zhu"
      expect(user.full_name).to eq("Zhu")
    end
  end
end
