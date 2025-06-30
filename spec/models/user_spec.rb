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

    context "for given_name" do
      it { should allow_value("Given Name").for(:given_name) }
      it { should_not allow_value("").for(:given_name) }
    end

    context "for usual_name" do
      it { should allow_value("Usual Name").for(:usual_name) }
      it { should_not allow_value("").for(:usual_name) }
    end

    context "for siret" do
      it { should allow_value("86043616100852").for(:siret) }
      it { should_not allow_value("").for(:siret) }
    end
  end

  describe ".from_omniauth" do
    subject(:from_omniauth) { described_class.from_omniauth(auth) }

    let(:siret) { "12345678901234" }
    let(:organizational_unit) { "Engineering Department" }
    # rubocop:disable RSpec/VerifiedDoubles
    let(:auth) do
      double(
        :auth,
        provider: "google_oauth2",
        uid: "123456789",
        info: double(email: "john.doe@example.com"),
        extra: double(
          raw_info: double(
            siret:,
            organizational_unit:,
            given_name: "John",
            usual_name: "Doe",
          )
        )
      )
    end
    # rubocop:enable RSpec/VerifiedDoubles

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
    end

    context "when team already exists" do
      let!(:existing_team) { create(:team, siret:, organizational_unit: "Old Department") }

      it "does not create a new team" do
        expect { from_omniauth }.not_to change(Team, :count)
      end

      it "updates the existing team's organizational_unit" do
        from_omniauth
        expect(existing_team.reload.organizational_unit).to eq(auth.extra.raw_info.organizational_unit)
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
      before do
        auth.info.stub(:email).and_return("invalid-email")
      end

      it "returns nil" do
        expect(from_omniauth).to be_nil
      end
    end
  end
end
