require "rails_helper"

RSpec.describe User do
  subject(:user) { build(:user) }

  it "has a valid factory" do
    expect(user).to be_valid
  end

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
end
